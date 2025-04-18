#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3Packages.requests

# NOTES
# my research seems to suggest forge can come in 3 varieties:
# ancient: this version only happens with *very* old versions (pre 1.5) and 
#    I *think* is just files to drop over the client.jar. very old method and one
#    we can probably save till the other two are working
# universal: This version comes with two files, universal.jar, and installer.jar
#    the first is the actual forge launcher, while the latter grabs the files
#    and libraries needed first.  I *think* the needed files are listed in
#    version.json inside the installer, and universal.jar is able to be
#    grabbed seperatly, so we don't need to fetch the installer during install
#    only when updating the lock files (which hopefully is never an issue, since
#    forge doesn't use this format anymore)
# modern: This version is just the installer.jar, and does some funky stuff to
#    finish the install, namely patching the actual client.jar directly
#    rather than using the pre-1.13 methods.  This one needs some work to make
#    happy, including patching the install_profile.json to remove the mapping
#    download step (because it doesn't work in a hermetic environment), and
#    stripping the hashes to make java happy.  We also need to fetch libraries as
#    with the above one, but the number of libraries is *massive*, so proper cache
#    is essential.  I'm also not 100% sure what patching methods are needed for each one,
#    so they may need some attention for current and future builds.

import base64
import concurrent.futures
import io
import json
import logging
import re
import requests
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from json import JSONEncoder, JSONDecoder
from pathlib import Path
from requests.adapters import HTTPAdapter, Retry
from typing import Any, Dict, List, Literal, Optional, Type, Union
from zipfile import ZipFile

MC_ENDPOINT = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json"
ENDPOINT = "https://files.minecraftforge.net/net/minecraftforge/forge/"
MAVEN = "https://maven.minecraftforge.net/net/minecraftforge/forge/"
MC_MAVEN = "https://maven.minecraftforge.net/net/minecraftforge/forge/"

TIMEOUT = 5
RETRIES = 5

logging.basicConfig(format="%(levelname)s:%(message)s", level=logging.INFO)

# Why are Types in Python so horrid...? Anyway, I put this under a class so you can collapse them all in your editor :)
class Types:
    class McVersion(str, Enum):
        V1_1 = "1.1"
        V1_2_3 = "1.2.3"
        V1_2_4 = "1.2.4"
        V1_3_1 = "1.3.1"
        V1_3_2 = "1.3.2"
        V1_4_2 = "1.4.2"
        V1_4_4 = "1.4.4"
        V1_4_5 = "1.4.5"
        V1_4_6 = "1.4.6"
        V1_4_7 = "1.4.7"
        V1_5_1 = "1.5.1"
        V1_5_2 = "1.5.2"
        V1_6_1 = "1.6.1"
        V1_6_2 = "1.6.2"
        V1_6_4 = "1.6.4"
        V1_7_2 = "1.7.2"
        V1_7_4 = "1.7.4"
        V1_7_5 = "1.7.5"
        V1_7_6 = "1.7.6"
        V1_7_7 = "1.7.7"
        V1_7_8 = "1.7.8"
        V1_7_9 = "1.7.9"
        V1_7_10 = "1.7.10"
        V1_8 = "1.8"
        V1_8_1 = "1.8.1"
        V1_8_2 = "1.8.2"
        V1_8_3 = "1.8.3"
        V1_8_4 = "1.8.4"
        V1_8_5 = "1.8.5"
        V1_8_6 = "1.8.6"
        V1_8_7 = "1.8.7"
        V1_8_8 = "1.8.8"
        V1_8_9 = "1.8.9"
        V1_9 = "1.9"
        V1_9_1 = "1.9.1"
        V1_9_2 = "1.9.2"
        V1_9_3 = "1.9.3"
        V1_9_4 = "1.9.4"
        V1_10 = "1.10"
        V1_10_1 = "1.10.1"
        V1_10_2 = "1.10.2"
        V1_11 = "1.11"
        V1_11_1 = "1.11.1"
        V1_11_2 = "1.11.2"
        V1_12 = "1.12"
        V1_12_1 = "1.12.1"
        V1_12_2 = "1.12.2"
        V1_13 = "1.13"
        V1_13_1 = "1.13.1"
        V1_13_2 = "1.13.2"
        V1_14 = "1.14"
        V1_14_1 = "1.14.1"
        V1_14_2 = "1.14.2"
        V1_14_3 = "1.14.3"
        V1_14_4 = "1.14.4"
        V1_15 = "1.15"
        V1_15_1 = "1.15.1"
        V1_15_2 = "1.15.2"
        V1_16 = "1.16"
        V1_16_1 = "1.16.1"
        V1_16_2 = "1.16.2"
        V1_16_3 = "1.16.3"
        V1_16_4 = "1.16.4"
        V1_16_5 = "1.16.5"
        V1_17 = "1.17"
        V1_17_1 = "1.17.1"
        V1_18 = "1.18"
        V1_18_1 = "1.18.1"
        V1_18_2 = "1.18.2"
        V1_19 = "1.19"
        V1_19_1 = "1.19.1"
        V1_19_2 = "1.19.2"
        V1_19_3 = "1.19.3"
        V1_19_4 = "1.19.4"
        V1_20 = "1.20"
        V1_20_1 = "1.20.1"
        V1_21 = "1.21"
        V1_21_1 = "1.21.1"
        V1_21_2 = "1.21.2"
        V1_21_3 = "1.21.3"
        V1_21_4 = "1.21.4"

    @dataclass
    class TxtEntry(JSONEncoder, JSONDecoder):
        txt: str

        @classmethod
        def from_dict(cls: Type["Types.TxtEntry"], data: Dict[str, Any]) -> "Types.TxtEntry":
            return cls(**data)

        def to_dict(self) -> Dict[str, Any]:
            return {"txt": self.txt}
        
    @dataclass
    class JarEntry(JSONEncoder, JSONDecoder):
        jar: str

        @classmethod
        def from_dict(cls: Type["Types.JarEntry"], data: Dict[str, Any]) -> "Types.JarEntry":
            return cls(**data)
        
        def to_dict(self) -> Dict[str, Any]:
            return {"jar": self.jar}

    @dataclass
    class ZipEntry(JSONEncoder, JSONDecoder):
        zip: str

        @classmethod
        def from_dict(cls: Type["Types.ZipEntry"], data: Dict[str, Any]) -> "Types.ZipEntry":
            return cls(**data)
        
        def to_dict(self) -> Dict[str, Any]:
            return {"zip": self.zip}

    @dataclass
    class Classifiers(JSONEncoder, JSONDecoder):
        mdk: Optional["Types.ZipEntry"] = None
        changelog: Optional["Types.TxtEntry"] = None
        sources: Optional["Types.JarEntry"] = None
        userdev: Optional["Types.JarEntry"] = None
        universal: Optional["Types.JarEntry"] = None
        installer: Optional["Types.JarEntry"] = None
        client: Optional["Types.ZipEntry"] = None

        @classmethod
        def from_dict(cls: Type["Types.Classifiers"], data: Dict[str, Any]) -> "Types.Classifiers":
            return Types.Classifiers(
                mdk=Types.ZipEntry.from_dict(data["mdk"]) if data.get("mdk") else None,
                changelog=Types.TxtEntry.from_dict(data["changelog"]) if data.get("changelog") else None,
                sources=Types.JarEntry.from_dict(data["sources"]) if data.get("sources") else None,
                userdev=Types.JarEntry.from_dict(data["userdev"]) if data.get("userdev") else None,
                universal=Types.JarEntry.from_dict(data["universal"]) if data.get("universal") else None,
                installer=Types.JarEntry.from_dict(data["installer"]) if data.get("installer") else None,
                client=Types.ZipEntry.from_dict(data["client"]) if data.get("client") else None,
            )
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "mdk": self.mdk.to_dict() if self.mdk else None,
                "changelog": self.changelog.to_dict() if self.changelog else None,
                "sources": self.sources.to_dict() if self.sources else None,
                "userdev": self.userdev.to_dict() if self.userdev else None,
                "universal": self.universal.to_dict() if self.universal else None,
                "installer": self.installer.to_dict() if self.installer else None,
                "client": self.client.to_dict() if self.client else None,
            }

    @dataclass
    class LauncherBuild(JSONEncoder, JSONDecoder):
        classifiers: "Types.Classifiers"

        @classmethod
        def from_dict(cls: Type["Types.LauncherBuild"], data: Dict[str, Any]) -> "Types.LauncherBuild":
            return cls(
                classifiers=Types.Classifiers.from_dict(data["classifiers"])
            )
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "classifiers": self.classifiers.to_dict()
            }

    class TypeEnum(str, Enum):
        OLD_ALPHA = "old_alpha"
        OLD_BETA = "old_beta"
        RELEASE = "release"
        SNAPSHOT = "snapshot"

    @dataclass
    class Latest(JSONEncoder, JSONDecoder):
        release: "Types.McVersion"
        snapshot: str

        @classmethod
        def from_dict(cls: Type["Types.Latest"], data: Dict[str, Any]) -> "Types.Latest":
            return cls(
                release=Types.McVersion(data["release"]),
                snapshot=data["snapshot"]
            )
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "release": self.release,
                "snapshot": self.snapshot
            }

    @dataclass
    class Version(JSONEncoder, JSONDecoder):
        id: str
        type: "Types.TypeEnum"
        url: str
        time: datetime
        release_time: datetime
        sha1: str
        compliance_level: int

        @classmethod
        def from_dict(cls: Type["Types.Version"], data: Dict[str, Any]) -> "Types.Version":
            return cls(
                id=data["id"],
                type=Types.TypeEnum(data["type"]),
                url=data["url"],
                time=datetime.fromisoformat(data["time"]),
                release_time=datetime.fromisoformat(data["releaseTime"]),
                sha1=data["sha1"],
                compliance_level=data["complianceLevel"]
            )
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "id": self.id,
                "type": self.type.value,
                "url": self.url,
                "time": self.time.isoformat(),
                "releaseTime": self.release_time.isoformat(),
                "sha1": self.sha1,
                "complianceLevel": self.compliance_level
            }

    @dataclass
    class GameVersions(JSONEncoder, JSONDecoder):
        latest: "Types.Latest"
        versions: List["Types.Version"]

        @classmethod
        def from_dict(cls: Type["Types.GameVersions"], data: Dict[str, Any]) -> "Types.GameVersions":
            return cls(
                latest=Types.Latest.from_dict(data["latest"]),
                versions=[Types.Version.from_dict(version) for version in data["versions"]]
            )
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "latest": self.latest.to_dict(),
                "versions": [version.to_dict() for version in self.versions]
            }

    @dataclass
    class LockLibrary(JSONEncoder, JSONDecoder):
        path: str
        sha1: str
        size: int
        url: str

        @classmethod
        def from_dict(cls: Type["Types.LockLibrary"], data: Dict[str, Any]) -> "Types.LockLibrary":
            return cls(**data)
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "path": self.path,
                "sha1": self.sha1,
                "size": self.size,
                "url": self.url
            }

    @dataclass
    class LockGameObject(JSONEncoder, JSONDecoder):
        sha1: str
        size: int
        url: str

        @classmethod
        def from_dict(cls: Type["Types.LockGameObject"], data: Dict[str, Any]) -> "Types.LockGameObject":
            return cls(**data)
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "sha1": self.sha1,
                "size": self.size,
                "url": self.url
            }

    @dataclass
    class LockGame(JSONEncoder, JSONDecoder):
        sha1: str
        libraries: List[str]
        server: Optional["Types.LockGameObject"] = None
        mappings: Optional["Types.LockGameObject"] = None

        @classmethod
        def from_dict(cls: Type["Types.LockGame"], data: Dict[str, Any]) -> "Types.LockGame":
            return Types.LockGame(
                sha1=data["sha1"],
                libraries=data["libraries"],
                server=Types.LockGameObject.from_dict(data["server"]) if data.get("server") and data["server"] != "" else None,
                mappings=Types.LockGameObject.from_dict(data["mappings"]) if data.get("mappings") and data["mappings"] != "" else None,
            )
        
        def to_dict(self) -> Dict[str, Any]:
            return {
                "sha1": self.sha1,
                "libraries": self.libraries,
                "server": self.server,
                "mappings": self.mappings,
            }
    
    @dataclass
    class LauncherVersionBase(JSONDecoder):
        type: str

        @classmethod
        def from_dict(cls: Type["Types.LauncherVersionBase"], data: Dict[str, Dict[str, Any]]) -> "Dict[str, Types.LauncherVersion]":
            items = data.items()
            if len(items) == 0:
                return {}
            
            version, data = list(items)[0]
            converted_data: Types.LauncherVersion
            if data["type"] == "universal":
                converted_data = Types.LauncherVersionUniversal.from_dict(data)
            elif data["type"] == "installer":
                converted_data = Types.LauncherVersionInstaller.from_dict(data)
            elif data["type"] == "ancient":
                converted_data = Types.LauncherVersionAncient.from_dict(data)
            else:
                raise ValueError(f"Unknown type: {data["type"]}")
            
            return {version: converted_data}

        def to_dict(self) -> Dict[str, Any]:
            raise NotImplementedError("Subclasses should implement this method")
        
        def __init__(self, *args, **kwargs):
            JSONDecoder.__init__(self, object_hook=self.object_hook, *args, **kwargs)

        def object_hook(self, dct):
            return self.from_dict(dct)

    @dataclass
    class LauncherVersionUniversal(JSONEncoder, JSONDecoder):
        type: Literal["universal"]
        universal_url: str
        universal_hash: str
        install_url: str
        install_hash: str
        libraries: List[str]

        @classmethod
        def from_dict(cls: Type["Types.LauncherVersionUniversal"], data: Dict[str, Any]) -> "Types.LauncherVersionUniversal":
            return cls(
                type=data["type"],
                universal_url=data["universalUrl"],
                universal_hash=data["universalHash"],
                install_url=data["installUrl"],
                install_hash=data["installHash"],
                libraries=data.get("libraries") or []
            )

        def to_dict(self) -> Dict[str, Any]:
            return {
                "type": self.type,
                "universalUrl": self.universal_url,
                "universalHash": self.universal_hash,
                "installUrl": self.install_url,
                "installHash": self.install_hash,
                "libraries": self.libraries
            }

    @dataclass
    class LauncherVersionInstaller(JSONEncoder, JSONDecoder):
        type: Literal["installer"]
        url: str
        hash: str
        libraries: List[str]

        @classmethod
        def from_dict(cls: Type["Types.LauncherVersionInstaller"], data: Dict[str, Any]) -> "Types.LauncherVersionInstaller":
            return cls(
                type=data["type"],
                url=data["url"],
                hash=data["hash"],
                libraries=data.get("libraries") or []
            )

        def to_dict(self) -> Dict[str, Any]:
            return {
                "type": self.type,
                "url": self.url,
                "hash": self.hash,
                "libraries": self.libraries
            }

    @dataclass
    class LauncherVersionAncient(JSONEncoder, JSONDecoder):
        type: Literal["ancient"]
        url: str
        hash: str
        libraries: List[str]

        @classmethod
        def from_dict(cls: Type["Types.LauncherVersionAncient"], data: Dict[str, Any]) -> "Types.LauncherVersionAncient":
            return cls(
                type=data["type"],
                url=data["url"],
                hash=data["hash"],
                libraries=data.get("libraries") or []
            )

        def to_dict(self) -> Dict[str, Any]:
            return {
                "type": self.type,
                "url": self.url,
                "hash": self.hash,
                "libraries": self.libraries
            }
        
    LauncherVersion = Union[LauncherVersionUniversal, LauncherVersionInstaller, LauncherVersionAncient]

    @dataclass
    class LauncherLibraryDownloads:
        artifact: "Types.LockLibrary"

        @classmethod
        def from_dict(cls: Type["Types.LauncherLibraryDownloads"], data: Dict[str, Any]) -> "Types.LauncherLibraryDownloads":
            return cls(
                artifact=Types.LockLibrary.from_dict(data["artifact"])
            )

        def to_dict(self) -> Dict[str, Any]:
            return {
                "artifact": self.artifact.to_dict()
            }

    @dataclass
    class LauncherLibrary:
        name: str
        downloads: "Types.LauncherLibraryDownloads"

        @classmethod
        def from_dict(cls: Type["Types.LauncherLibrary"], data: Dict[str, Any]) -> "Types.LauncherLibrary":
            return cls(
                name=data["name"],
                downloads=Types.LauncherLibraryDownloads.from_dict(data["downloads"])
            )

        def to_dict(self) -> Dict[str, Any]:
            return {
                "name": self.name,
                "downloads": self.downloads.to_dict()
            }
    
# Define a custom HTTP adapter with a timeout
class TimeoutHTTPAdapter(HTTPAdapter):
    def __init__(self, *args, **kwargs):
        """
        Initialize the adapter with a default timeout.
        """
        self.timeout = TIMEOUT
        if "timeout" in kwargs:
            self.timeout = kwargs["timeout"]
            del kwargs["timeout"]
        super().__init__(*args, **kwargs)

    def send(self, request, **kwargs):
        """
        Send the request with the specified timeout.
        """
        timeout = kwargs.get("timeout")
        if timeout is None:
            kwargs["timeout"] = self.timeout
        return super().send(request, **kwargs)

def make_client() -> requests.Session:
    """
    Create and configure a requests session with retry and timeout settings.
    """
    http = requests.Session()
    retries = Retry(total=RETRIES, backoff_factor=2, status_forcelist=[429, 501, 502, 503, 504])
    adapter = TimeoutHTTPAdapter(max_retries=retries, pool_connections=100000, pool_maxsize=100000)
    http.mount("https://", adapter)
    http.verify = True 
    return http

def get_launcher_versions(client: requests.Session) -> Dict[Types.McVersion, List[str]]:
    """
    Fetch launcher versions from the endpoint.
    """
    logging.info("Fetching launcher versions")
    data = client.get(f"{ENDPOINT}/maven-metadata.json").json()
    return data

def get_game_versions(client: requests.Session) -> Types.GameVersions:
    """
    Fetch game versions from the endpoint.
    """
    logging.info("Fetching launcher versions")
    return Types.GameVersions.from_dict(client.get(MC_ENDPOINT).json())

def get_launcher_build(client: requests.Session, version: str) -> Types.LauncherBuild:
    """
    Fetch launcher build information for a specific version.
    """
    logging.info(f"Fetching launcher build for {version}")
    return Types.LauncherBuild.from_dict(client.get(f"{ENDPOINT}/{version}/meta.json").json())

def get_game_version_data(client: requests.Session, version_url: str):
    """
    Fetch game version data from a given URL.
    """
    return client.get(version_url).json()

def hex_to_sri(hex_hash: str) -> str:
    """
    Convert a hexadecimal hash to an SRI hash.
    """
    hash_bytes = bytes.fromhex(hex_hash)
    base64_hash = base64.b64encode(hash_bytes).decode("utf-8")
    return f"md5-{base64_hash}"

def get_launcher_libraries(client: requests.Session, version: str) -> List[Types.LauncherLibrary]:
    """
    Fetch launcher libraries for a specific version.
    """
    logging.info(f"Fetching installer for {version}")
    installer_response = client.get(f"{MAVEN}/{version}/forge-{version}-installer.jar")
    installer_content = io.BytesIO(installer_response.content)
    libraries = []
    with ZipFile(installer_content) as zip:
        with zip.open("install_profile.json") as profile:
            profile_data = json.load(profile)
            libraries.extend(profile_data["libraries"])
        with zip.open("version.json") as version_file:
            version_data = json.load(version_file)
            libraries.extend(version_data["libraries"])
    return [Types.LauncherLibrary.from_dict(x) for x in libraries]

def fetch_game_version(version: Types.Version, client: requests.Session, game_versions: Dict[str, Types.LockGame], library_versions: Dict[str, Types.LockLibrary]):
    """
    Fetch game version data and update the game_versions and library_versions dictionaries.
    """
    if version.type != Types.TypeEnum.RELEASE:
        return

    version_id = version.id
    if version_id in game_versions and game_versions[version_id].sha1 == version.sha1:
        return

    data = get_game_version_data(client, version.url)
    
    libraries = []
    for library in data["libraries"]:
        if not library["name"] in library_versions:
            if "artifact" in library["downloads"]:
                library_versions[library["name"]] = library["downloads"]["artifact"]
            elif "classifiers" in library["downloads"]:
                if "natives-linux" in library["downloads"]["classifiers"]:
                    library_versions[library["name"]] = library["downloads"]["classifiers"]["natives-linux"]
            else:
                logging.info(json.dumps(library, indent=4))
        libraries.append(library["name"])

    mappings = None
    server = None
    if "server" in data["downloads"]:
        server = Types.LockGameObject.from_dict(data["downloads"]["server"])
    if "server_mappings" in data["downloads"]:
        mappings = Types.LockGameObject.from_dict(data["downloads"]["server_mappings"])

    game_versions[version_id] = Types.LockGame(
        version.sha1,
        libraries,
        server,
        mappings,
    )

def fetch_launcher_version(mc_version: Types.McVersion, builds: List[str], client: requests.Session, launcher_versions: Dict[str, Dict[str, Types.LauncherVersion]], library_versions: Dict[str, Types.LockLibrary], game_versions: Dict[str, Types.LockGame]):
    """
    Fetch launcher version data and update the launcher_versions, library_versions, and game_versions dictionaries. Currently an issue where it stops early and doesn't process them all...
    """
    if mc_version not in launcher_versions:
        launcher_versions[mc_version] = {}

    for build in builds:
        build_number = build.split("-")[1]
        if build_number != "47.3.12":
            continue
        if build_number in launcher_versions[mc_version]:
            continue

        launcher_build = get_launcher_build(client, build)
        classifiers = launcher_build.classifiers

        if classifiers.installer is not None:
            launcher_versions[mc_version][build_number] = Types.LauncherVersionInstaller(
                type="installer",
                url=f"{MAVEN}/{build}/forge-{build}-installer.jar",
                hash=hex_to_sri(classifiers.installer.jar),
                libraries = [],
            )
        elif classifiers.universal is not None:
            launcher_versions[mc_version][build_number] = Types.LauncherVersionUniversal(
                type="universal",
                universal_url = f"{MAVEN}/{build}/forge-{build}-universal.jar",
                universal_hash = hex_to_sri(classifiers.universal.jar),
                install_url = f"{MAVEN}/{build}/forge-{build}-installer.jar",
                install_hash = hex_to_sri(classifiers.universal.jar),
                libraries = [],
            )
        elif classifiers.client is not None:
            launcher_versions[mc_version][build_number] = Types.LauncherVersionAncient(
                type="ancient",
                url=f"{MAVEN}/{build}/forge-{build}-client.zip",
                hash=hex_to_sri(classifiers.client.zip),
                libraries = [],
            )
        else:
            logging.info(f"no installer or client in {build}")
            logging.info(launcher_build)

        forge_libraries = get_launcher_libraries(client, build)
        for forge_library in forge_libraries:
            library_versions[forge_library.name] = forge_library.downloads.artifact
            launcher_versions[mc_version][build_number].libraries.append(forge_library.name)

def main(game_versions: Dict[str, Types.LockGame], launcher_versions: Dict[str, Dict[str, Types.LauncherVersion]], library_versions: Dict[str, Types.LockLibrary], client: requests.Session):
    """
    Main function to fetch game and launcher versions and update the respective dictionaries.
    """
    logging.info("Starting fetch")

    game_manifest = get_game_versions(client)

    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = []
        for version in game_manifest.versions:
            futures.append(executor.submit(fetch_game_version, version, client, game_versions, library_versions))
        concurrent.futures.wait(futures)

    launcher_manifest = get_launcher_versions(client)

    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = []
        for mc_version, builds in launcher_manifest.items():
            futures.append(executor.submit(fetch_launcher_version, mc_version, builds, client, launcher_versions, library_versions, game_versions))
        concurrent.futures.wait(futures)

    return (game_versions, launcher_versions, library_versions)

if __name__ == "__main__":
    folder = Path(__file__).parent
    launcher_path = folder / "lock_launcher.json"
    game_path = folder / "lock_game.json"
    library_path = folder / "lock_libraries.json"

    # Custom JSON encoder to handle custom types
    class Encoder(JSONEncoder):
        def default(self, o):
            return o.to_dict()
        
    def load_json(path: Path, cls=None) -> dict:
        """
        Load JSON data from a file, optionally converting it to a specific class.
        """
        if not path.exists():
            path.touch()
            return {}
        if path.stat().st_size == 0:
            return {}
        with open(path, "r") as file:
            data = json.load(file)
            if cls:
                return {k: cls.from_dict(v) for k, v in data.items()}
            return data
        
    def version_key(version: str) -> tuple:
        """
        Generate a version key for sorting.
        """
        parts = re.split(r"(\d+)", version)
        return tuple(int(part) if part.isdigit() else part for part in parts)

    def save_json(path: Path, data: dict) -> None:
        """
        Save JSON data to a file.
        """
        with open(path, "w") as file:
            if isinstance(data, dict):
                sorted_data = dict(sorted(data.items(), key=lambda item: version_key(item[0])))
            else:
                sorted_data = sorted(data, key=lambda item: version_key(item[0]))
            json.dump(sorted_data, file, indent=4, cls=Encoder)

    # Load existing data
    game_versions = load_json(game_path, Types.LockGame)
    launcher_versions = load_json(launcher_path, Types.LauncherVersionBase)
    library_versions = load_json(library_path, Types.LockLibrary)

    # Fetch and update data
    game_versions, launcher_versions, library_versions = main(
        game_versions,
        launcher_versions,
        library_versions,
        make_client(),
    )

    # Save updated data
    save_json(game_path, game_versions)
    save_json(launcher_path, launcher_versions)
    save_json(library_path, library_versions)