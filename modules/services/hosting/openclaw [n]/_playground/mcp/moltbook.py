# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=2,<3", "aiohttp", "pydantic"]
# ///
import os
import re
import json
from typing import Optional

import aiohttp
from pydantic import BaseModel, Field

API_BASE = "https://www.moltbook.com/api/v1"  # www is mandatory; without it the auth header is stripped
KEY_FILE = "/run/openclaw-secrets/moltbook"

_UNITS = {
    "zero": 0,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
    "thirteen": 13,
    "fourteen": 14,
    "fifteen": 15,
    "sixteen": 16,
    "seventeen": 17,
    "eighteen": 18,
    "nineteen": 19,
}
_TENS = {
    "twenty": 20,
    "thirty": 30,
    "forty": 40,
    "fifty": 50,
    "sixty": 60,
    "seventy": 70,
    "eighty": 80,
    "ninety": 90,
}


def _load_key() -> str:
    raw = os.environ.get("MOLTBOOK_API_KEY", "").strip() or KEY_FILE
    if raw.startswith("/"):
        try:
            with open(raw) as f:
                return f.read().strip()
        except OSError:
            return ""
    return raw


def _clip(text, n: int) -> str:
    if text is None:
        return ""
    s = str(text).replace("\n", " ").strip()
    return s if len(s) <= n else s[: n - 1] + "…"


def _words_to_numbers(tokens):
    out, i = [], 0
    while i < len(tokens):
        t = tokens[i]
        if t.isdigit():
            out.append(float(t))
            i += 1
            continue
        if t in _TENS:
            val = _TENS[t]
            if (
                i + 1 < len(tokens)
                and tokens[i + 1] in _UNITS
                and 0 < _UNITS[tokens[i + 1]] < 10
            ):
                val += _UNITS[tokens[i + 1]]
                i += 2
            else:
                i += 1
            out.append(float(val))
            continue
        if t in _UNITS:
            out.append(float(_UNITS[t]))
            i += 1
            continue
        i += 1
    return out


def _solve_challenge(challenge: str):
    """Best-effort solve of the obfuscated math challenge. Returns a string or None."""
    text = re.sub(r"[^a-z0-9 ]+", " ", (challenge or "").lower())
    tokens = text.split()
    joined = " ".join(tokens)
    nums = _words_to_numbers(tokens)
    op = None
    for phrase, symbol in (
        ("slows down by", "-"),
        ("slows by", "-"),
        ("decreases by", "-"),
        ("reduces by", "-"),
        ("minus", "-"),
        ("speeds up by", "+"),
        ("increases by", "+"),
        ("plus", "+"),
        ("multiplied by", "*"),
        ("times", "*"),
        ("divided by", "/"),
    ):
        if phrase in joined:
            op = symbol
            break
    if op is None or len(nums) != 2:
        return None
    a, b = nums
    try:
        if op == "+":
            r = a + b
        elif op == "-":
            r = a - b
        elif op == "*":
            r = a * b
        else:
            if b == 0:
                return None
            r = a / b
    except Exception:
        return None
    return f"{r:.2f}"


class Tools:
    class Valves(BaseModel):
        auto_solve_verification: bool = Field(
            True,
            description="Try to solve Moltbook's math verification challenge automatically. "
            "If wrong answers accumulate (10 failures = suspension), set this to false.",
        )
        max_body_chars: int = Field(
            700, description="Max characters of a post body returned to the model."
        )

    def __init__(self):
        self.valves = self.Valves()
        self.api_key = _load_key()

    # ---------- transport ----------

    async def _req(self, method: str, path: str, *, params=None, body=None):
        if not self.api_key:
            return {
                "ok": False,
                "error": f"Moltbook API key not found (env MOLTBOOK_API_KEY or {KEY_FILE}).",
            }
        headers = {"Authorization": f"Bearer {self.api_key}"}
        timeout = aiohttp.ClientTimeout(total=20)
        try:
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.request(
                    method, API_BASE + path, headers=headers, params=params, json=body
                ) as resp:
                    status = resp.status
                    try:
                        data = await resp.json(content_type=None)
                    except Exception:
                        data = {"raw": _clip(await resp.text(), 300)}
        except Exception as e:
            return {"ok": False, "error": f"network error: {type(e).__name__}: {e}"}

        if status == 401:
            return {
                "ok": False,
                "error": "401 unauthorized: Moltbook API key is missing or invalid.",
            }
        if status == 429:
            retry = data.get("retry_after_seconds") or data.get("retry_after_minutes")
            return {"ok": False, "error": f"429 rate limited. retry_after={retry}"}
        if status >= 400:
            msg = data.get("error") or data.get("message") or data
            return {"ok": False, "status": status, "error": _clip(msg, 300)}
        return {
            "ok": True,
            "status": status,
            "data": data if isinstance(data, dict) else {"data": data},
        }

    async def _maybe_verify(self, d: dict, content_type: str):
        node = d.get(content_type) or {}
        v = node.get("verification") if isinstance(node, dict) else None
        if not v:
            return None
        code = v.get("verification_code")
        challenge = v.get("challenge_text") or ""
        if self.valves.auto_solve_verification:
            answer = _solve_challenge(challenge)
            if answer is not None:
                rv = await self._req(
                    "POST",
                    "/verify",
                    body={"verification_code": code, "answer": answer},
                )
                if rv.get("ok") and rv["data"].get("success"):
                    return {"verified": True, "answer_sent": answer}
        return {
            "verified": False,
            "verification_code": code,
            "challenge_text": _clip(challenge, 280),
            "hint": "Call molt_verify with this verification_code and a numeric answer like '15.00'.",
        }

    async def _finish_write(self, r, content_type: str) -> str:
        if not r["ok"]:
            return json.dumps(r, ensure_ascii=False)
        d = r["data"]
        node = d.get(content_type) or {}
        out = {
            "success": bool(d.get("success", True)),
            "id": node.get("id") if isinstance(node, dict) else None,
            "verification_status": (
                node.get("verification_status") if isinstance(node, dict) else None
            ),
            "message": _clip(d.get("message"), 160),
        }
        ver = await self._maybe_verify(d, content_type)
        if ver:
            out["verification"] = ver
        return json.dumps(out, ensure_ascii=False)

    # ---------- read tools ----------

    async def molt_home(self) -> str:
        """Get your Moltbook dashboard: karma, unread notifications, activity on your posts, and recent posts from accounts you follow. Call this first on every check-in.
        :return: compact JSON
        """
        r = await self._req("GET", "/home")
        if not r["ok"]:
            return json.dumps(r, ensure_ascii=False)
        d = r["data"]
        acct = d.get("your_account") or {}
        follow = (d.get("posts_from_accounts_you_follow") or {}).get("posts") or []
        out = {
            "you": {
                "name": acct.get("name"),
                "karma": acct.get("karma"),
                "unread": acct.get("unread_notification_count"),
            },
            "activity_on_your_posts": [
                {
                    "post_id": a.get("post_id"),
                    "title": _clip(a.get("post_title"), 100),
                    "new": a.get("new_notification_count"),
                    "preview": _clip(a.get("preview"), 140),
                }
                for a in (d.get("activity_on_your_posts") or [])[:3]
            ],
            "following": [
                {
                    "post_id": p.get("post_id"),
                    "title": _clip(p.get("title"), 100),
                    "author": p.get("author_name"),
                    "upvotes": p.get("upvotes"),
                    "comments": p.get("comment_count"),
                }
                for p in follow[:5]
            ],
            "next": _clip((d.get("what_to_do_next") or [None])[0], 160),
        }
        return json.dumps(out, ensure_ascii=False)

    async def molt_feed(
        self, sort: str = "hot", limit: int = 5, following_only: bool = False
    ) -> str:
        """Browse Moltbook posts. Returns only ids, titles, authors and counts so the response stays small. Use molt_read_post to read one.
        :param sort: "hot", "new", or "top"
        :param limit: number of posts, 1-10 (default 5)
        :param following_only: True = only accounts you follow
        :return: compact JSON list
        """
        limit = max(1, min(int(limit or 5), 10))
        params = {
            "sort": sort if sort in ("hot", "new", "top") else "hot",
            "limit": limit,
        }
        if following_only:
            params["filter"] = "following"
        r = await self._req("GET", "/feed", params=params)
        if not r["ok"]:
            return json.dumps(r, ensure_ascii=False)
        d = r["data"]
        posts = d.get("posts") or d.get("data") or []
        if isinstance(posts, dict):
            posts = posts.get("posts") or []
        out = []
        for p in posts[:limit]:
            author = p.get("author")
            submolt = p.get("submolt")
            out.append(
                {
                    "id": p.get("id") or p.get("post_id"),
                    "title": _clip(p.get("title"), 100),
                    "author": (
                        author.get("name")
                        if isinstance(author, dict)
                        else p.get("author_name")
                    ),
                    "upvotes": p.get("upvotes"),
                    "comments": p.get("comment_count") or p.get("comments_count"),
                    "submolt": (
                        submolt.get("name")
                        if isinstance(submolt, dict)
                        else p.get("submolt_name")
                    ),
                }
            )
        return json.dumps(
            {"posts": out, "has_more": d.get("has_more")}, ensure_ascii=False
        )

    async def molt_read_post(self, post_id: str, max_comments: int = 4) -> str:
        """Read one post and its top comments. Body is truncated; comment ids are included so you can reply.
        :param post_id: the post id from molt_feed or molt_home
        :param max_comments: number of top-level comments, 1-6
        :return: compact JSON with the post body and comments
        """
        max_comments = max(1, min(int(max_comments or 4), 6))
        rp = await self._req("GET", f"/posts/{post_id}")
        if not rp["ok"]:
            return json.dumps(rp, ensure_ascii=False)
        d = rp["data"]
        p = d.get("post") or d.get("data") or d
        if isinstance(p, dict) and "post" in p and isinstance(p["post"], dict):
            p = p["post"]
        comments = []
        rc = await self._req(
            "GET",
            f"/posts/{post_id}/comments",
            params={"sort": "best", "limit": max_comments},
        )
        if rc["ok"]:
            cd = rc["data"]
            raw = cd.get("comments") or (cd.get("data") or {}).get("comments") or []
            for c in raw[:max_comments]:
                ca = c.get("author")
                comments.append(
                    {
                        "id": c.get("id"),
                        "author": (
                            ca.get("name")
                            if isinstance(ca, dict)
                            else c.get("author_name")
                        ),
                        "upvotes": c.get("upvotes"),
                        "text": _clip(c.get("content"), 220),
                        "replies": len(c.get("replies") or []),
                    }
                )
        author = p.get("author")
        submolt = p.get("submolt")
        return json.dumps(
            {
                "id": p.get("id") or post_id,
                "title": _clip(p.get("title"), 120),
                "author": (
                    author.get("name")
                    if isinstance(author, dict)
                    else p.get("author_name")
                ),
                "submolt": (
                    submolt.get("name")
                    if isinstance(submolt, dict)
                    else p.get("submolt_name")
                ),
                "upvotes": p.get("upvotes"),
                "body": _clip(p.get("content"), self.valves.max_body_chars),
                "comments": comments,
            },
            ensure_ascii=False,
        )

    async def molt_search(self, query: str, limit: int = 5) -> str:
        """Semantic search across Moltbook posts and comments. Returns ids, titles and short previews.
        :param query: natural-language query
        :param limit: number of results, 1-10
        :return: compact JSON list
        """
        limit = max(1, min(int(limit or 5), 10))
        r = await self._req(
            "GET", "/search", params={"q": query[:400], "limit": limit, "type": "all"}
        )
        if not r["ok"]:
            return json.dumps(r, ensure_ascii=False)
        d = r["data"]
        results = d.get("results") or d.get("data") or []
        out = []
        for x in results[:limit]:
            a = x.get("author")
            out.append(
                {
                    "type": x.get("type"),
                    "post_id": x.get("post_id") or x.get("id"),
                    "comment_id": x.get("id") if x.get("type") == "comment" else None,
                    "title": _clip(x.get("title"), 100),
                    "author": (
                        a.get("name") if isinstance(a, dict) else x.get("author_name")
                    ),
                    "preview": _clip(x.get("content"), 160),
                    "upvotes": x.get("upvotes"),
                }
            )
        return json.dumps(
            {"results": out, "has_more": d.get("has_more")}, ensure_ascii=False
        )

    # ---------- write tools ----------

    async def molt_post(self, submolt: str, title: str, content: str = "") -> str:
        """Create a new Moltbook post. Rate limit: 1 post per 30 minutes (2 hours if the account is under 24h old).
        :param submolt: community name, e.g. "general"
        :param title: post title, max 300 characters
        :param content: post body, optional
        :return: result JSON; may include a verification challenge
        """
        body = {
            "submolt_name": submolt,
            "title": (title or "")[:300],
            "content": content or "",
        }
        r = await self._req("POST", "/posts", body=body)
        return await self._finish_write(r, "post")

    async def molt_reply(
        self, post_id: str, content: str, parent_id: Optional[str] = None
    ) -> str:
        """Reply to a post or to another comment. Rate limit: 1 comment per 20 seconds, 50 per day.
        :param post_id: the post to comment on
        :param content: your comment text
        :param parent_id: optional comment id to reply to; omit for a top-level comment
        :return: result JSON; may include a verification challenge
        """
        body = {"content": content}
        if parent_id:
            body["parent_id"] = parent_id
        r = await self._req("POST", f"/posts/{post_id}/comments", body=body)
        return await self._finish_write(r, "comment")

    async def molt_vote(
        self, target_id: str, target: str = "post", direction: str = "up"
    ) -> str:
        """Upvote or downvote a post or comment.
        :param target_id: post or comment id
        :param target: "post" or "comment"
        :param direction: "up" or "down"
        :return: result JSON
        """
        verb = "downvote" if direction == "down" else "upvote"
        path = (
            f"/comments/{target_id}/{verb}"
            if target == "comment"
            else f"/posts/{target_id}/{verb}"
        )
        r = await self._req("POST", path)
        if not r["ok"]:
            return json.dumps(r, ensure_ascii=False)
        d = r["data"]
        return json.dumps(
            {
                "success": bool(d.get("success", True)),
                "message": _clip(d.get("message"), 120),
                "already_following": d.get("already_following"),
            },
            ensure_ascii=False,
        )

    async def molt_verify(self, verification_code: str, answer: str) -> str:
        """Submit the answer to a verification challenge so your post or comment becomes visible. The answer must be a number like "15.00".
        :param verification_code: the code returned by molt_post or molt_reply
        :param answer: your numeric answer as a string, e.g. "15.00"
        :return: result JSON
        """
        r = await self._req(
            "POST",
            "/verify",
            body={"verification_code": verification_code, "answer": str(answer)},
        )
        if not r["ok"]:
            return json.dumps(r, ensure_ascii=False)
        d = r["data"]
        return json.dumps(
            {
                "success": bool(d.get("success")),
                "message": _clip(d.get("message") or d.get("error"), 160),
                "content_id": d.get("content_id"),
            },
            ensure_ascii=False,
        )


# ---------- MCP entrypoint (stdio) ----------

if __name__ == "__main__":
    from mcp.server.mcpserver import MCPServer

    mcp = MCPServer("moltbook")
    _t = Tools()
    for _name in dir(_t):
        if _name.startswith("molt_"):
            mcp.tool()(getattr(_t, _name))
    mcp.run()