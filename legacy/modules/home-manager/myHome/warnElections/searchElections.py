import requests
import re
import time
from datetime import datetime, timedelta
import subprocess
from bs4 import BeautifulSoup
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

MONTHS = {
    'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4,
    'maio': 5, 'junho': 6, 'julho': 7, 'agosto': 8,
    'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12
}

MONTH_NAMES = {v: k for k, v in MONTHS.items()}

def send_notification(subject, body):
    """Send critical desktop notification AND phone notification"""
    # Wait for notification daemon to be available
    max_attempts = 1000
    for attempt in range(max_attempts):
        try:
            subprocess.run([
                "/run/current-system/sw/bin/notify-send",
                "-u", "critical", 
                subject, 
                body
            ], check=True, capture_output=True, text=True)
            print(f"Desktop notification sent: {subject}")
            break
        except subprocess.CalledProcessError as e:
            stderr = e.stderr or ""
            if "org.freedesktop.Notifications" in stderr and attempt < max_attempts - 1:
                print(f"Notification daemon not ready, waiting... (attempt {attempt + 1}/{max_attempts})")
                time.sleep(2)
            else:
                print(f"Failed to send desktop notification: {e}")
                break
        except Exception as e:
            print(f"Failed to send desktop notification: {e}")
            break
    
    send_pushbullet_notification(subject, body)

def send_pushbullet_notification(title, body):
    """Send notification via Pushbullet"""
    access_token = "o.yAa9ipEqeu3UsAPDhcmSf5SqNyylhuxp"
        
    data = {
        "type": "note",
        "title": title,
        "body": body
    }
    headers = {
        "Access-Token": access_token,
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(
            "https://api.pushbullet.com/v2/pushes",
            json=data,
            headers=headers
        )
        if response.status_code == 200:
            print("📱 Phone notification sent via Pushbullet")
        else:
            print(f"Pushbullet error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Pushbullet failed: {e}")

def parse_date(date_str, year):
    """Parse Portuguese date string. Returns (datetime, is_approximate, original_date_str)"""
    original = date_str
    date_str = date_str.lower().strip()
    
    # First, handle the common Portuguese format "X de MONTH"
    de_pattern = re.search(
        r'(\d{1,2})\s+de\s+([a-záéíóúãõâêôç]+)', 
        date_str,
        flags=re.IGNORECASE
    )
    if de_pattern:
        try:
            day = int(de_pattern.group(1))
            month_str = de_pattern.group(2).strip()
            for month_name, month_num in MONTHS.items():
                if month_name.startswith(month_str):
                    return (datetime(year, month_num, day), False, original)
        except (ValueError, KeyError):
            pass
    
    # Then check for other day-month patterns (e.g. "23 março")
    day_month = re.search(
        r'(\d{1,2})[\s\-/]*([a-záéíóúãõâêôç]+)', 
        date_str,
        flags=re.IGNORECASE
    )
    if day_month:
        try:
            day = int(day_month.group(1))
            month_str = day_month.group(2).strip()
            if month_str not in ['de', 'do', 'da', 'das', 'dos']:
                for month_name, month_num in MONTHS.items():
                    if month_name.startswith(month_str):
                        return (datetime(year, month_num, day), False, original)
        except (ValueError, KeyError):
            pass
    
    # Then handle month ranges (e.g. "setembro/outubro") - APPROXIMATE
    if '/' in date_str:
        months = [m.strip() for m in date_str.split('/')]
        for month in months:
            if month in ['de', 'do', 'da', 'das', 'dos']:
                continue
            for month_name, month_num in MONTHS.items():
                if month_name.startswith(month):
                    # Use 1st day of first month for worst-case notifications
                    return (datetime(year, month_num, 1), True, original)
    
    # Then single month names (e.g. "novembro") - APPROXIMATE
    for month_name, month_num in MONTHS.items():
        if month_name in date_str:
            # Use 1st day of month for worst-case notifications
            return (datetime(year, month_num, 1), True, original)
    
    print(f"Failed to parse: {original}")
    return (None, False, original)

def format_election_date(date_obj, is_approximate, original_str):
    """Format election date for display"""
    if is_approximate:
        return original_str.title()
    else:
        return date_obj.strftime('%d/%m/%Y')

def check_elections():
    try:
        today = datetime.today()
        start_date = today + timedelta(weeks=2)
        end_date = today + timedelta(days=60)
        print(f"Today: {today.strftime('%Y-%m-%d')}")
        print(f"Checking range: {start_date.strftime('%d/%m/%Y')} - {end_date.strftime('%d/%m/%Y')}\n")

        # Scrape election data
        url = 'https://www.cne.pt/content/calendario'
        response = requests.get(url, timeout=10, verify=False)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        table = soup.find('table')
        
        if not table:
            send_notification("Scraping Error", "No calendar table found")
            return

        elections = []  # List of (date, is_approximate, original_str, etype)
        parsing_errors = []
        
        print("All Election Entries:")
        for row in table.find_all('tr')[1:]:
            cols = row.find_all('td')
            if len(cols) < 4:
                continue
                
            year_str = cols[0].get_text(strip=True)
            raw_date = cols[1].get_text(strip=True)
            etype = cols[2].get_text(strip=True)
            
            print(f"Year: {year_str}")
            print(f"Date: {raw_date}")
            print(f"Type: {etype}")
            print('-' * 40)
            
            try:
                year = int(year_str)
                parsed_date, is_approx, original = parse_date(raw_date, year)
                
                if parsed_date:
                    elections.append((parsed_date, is_approx, original, etype))
                    approx_str = " (APPROXIMATE - using 1st for notifications)" if is_approx else ""
                    print(f"Parsed as: {parsed_date.strftime('%d/%m/%Y')}{approx_str}\n")
                else:
                    parsing_errors.append(raw_date)
            except ValueError:
                parsing_errors.append(raw_date)
                print(f"Invalid year: {year_str}\n")

        # ============================================================
        # UNIT TESTS - Uncomment the section you want to test
        # ============================================================
        
        # ==================== APPROXIMATE ELECTIONS ====================
        # These elections have month-only dates (e.g., "janeiro" or "setembro/outubro")
        # They get 16 generic notifications: 32,27,22,21,15,14,13,12,10,8,6,5,4,3,2,1 days before
        # Then daily "THIS MONTH" alerts once inside the month
        
        # TEST 1: Generic notification 32 days before approximate election (single month)
        # elections.append((datetime.today() + timedelta(days=32), True, "março", "Test: Approximate Election"))
        
        # TEST 2: Generic notification 27 days before approximate election (single month)
        # elections.append((datetime.today() + timedelta(days=27), True, "abril", "Test: Approximate Election"))
        
        # TEST 3: Generic notification 22 days before approximate election (single month)
        # elections.append((datetime.today() + timedelta(days=22), True, "maio", "Test: Approximate Election"))
        
        # TEST 4: Additional approximate notifications (21, 15, 14, 13, 12, 10, 8, 6, 5, 4, 3, 2, 1 days before)
        # These are the EXTRA notifications that approximate elections get
        # elections.append((datetime.today() + timedelta(days=21), True, "junho", "Test: 21 days before"))
        # elections.append((datetime.today() + timedelta(days=15), True, "julho", "Test: 15 days before"))
        # elections.append((datetime.today() + timedelta(days=14), True, "agosto", "Test: 14 days before"))
        # elections.append((datetime.today() + timedelta(days=13), True, "setembro", "Test: 13 days before"))
        # elections.append((datetime.today() + timedelta(days=12), True, "outubro", "Test: 12 days before"))
        # elections.append((datetime.today() + timedelta(days=10), True, "novembro", "Test: 10 days before"))
        # elections.append((datetime.today() + timedelta(days=8), True, "dezembro", "Test: 8 days before"))
        # elections.append((datetime.today() + timedelta(days=6), True, "janeiro", "Test: 6 days before"))
        # elections.append((datetime.today() + timedelta(days=5), True, "fevereiro", "Test: 5 days before"))
        # elections.append((datetime.today() + timedelta(days=4), True, "março", "Test: 4 days before"))
        # elections.append((datetime.today() + timedelta(days=3), True, "abril", "Test: 3 days before"))
        # elections.append((datetime.today() + timedelta(days=2), True, "maio", "Test: 2 days before"))
        # elections.append((datetime.today() + timedelta(days=1), True, "junho", "Test: 1 day before"))
        
        # TEST 5: We are INSIDE an approximate election month (single month)
        # Should trigger daily "Election THIS MONTH" alert
        # elections.append((datetime(today.year, today.month, 1), True, "dezembro", "Test: Inside Approximate Month"))
        
        # TEST 6: We are INSIDE an approximate election month range (month/month)
        # Should trigger daily "Election THIS MONTH" alert
        # elections.append((datetime(today.year, today.month, 1), True, "dezembro/janeiro", "Test: Inside Month Range"))
        
        # TEST 7: We are in the SECOND month of a month/month range
        # Should trigger daily "Election THIS MONTH" alert
        # Example: if today is December, this simulates "novembro/dezembro" election
        # elections.append((datetime(today.year, today.month - 1 if today.month > 1 else 12, 1), True, f"novembro/dezembro", "Test: Second Month of Range"))
        
        # TEST 8: REAL SCENARIO - Janeiro 2026 election (run this on Dec 27, 2025!)
        # Should trigger notification TODAY because we're 5 days from Jan 1
        # elections.append((datetime(2026, 1, 1), True, "janeiro", "Eleição do Presidente da República"))
        
        # ==================== EXACT DATE ELECTIONS ====================
        # These elections have specific dates (e.g., "26 de janeiro")
        # They get fewer notifications than approximate elections:
        # - Generic: 32, 27, 22 days before
        # - Early voting: 21 (ELEITORES DOENTES tomorrow), 20 (today), 15 (EM MOBILIDADE tomorrow), 
        #                 14 (today), 13 (DESLOCADOS tomorrow), 12 (today)
        # - Election day: 1 (tomorrow), 0 (today)
        
        # TEST 9: Generic notification 32 days before exact election
        # elections.append((datetime.today() + timedelta(days=32), False, "32 days exact", "Test: Exact 32 days - Generic"))
        
        # TEST 10: Generic notification 27 days before exact election
        # elections.append((datetime.today() + timedelta(days=27), False, "27 days exact", "Test: Exact 27 days - Generic"))
        
        # TEST 11: Generic notification 22 days before exact election
        # elections.append((datetime.today() + timedelta(days=22), False, "22 days exact", "Test: Exact 22 days - Generic"))
        
        # TEST 12: Early voting notification 21 days before (ELEITORES DOENTES INTERNADOS - TOMORROW)
        # elections.append((datetime.today() + timedelta(days=21), False, "21 days exact", "Test: Exact 21 days - Early Voting Tomorrow"))
        
        # TEST 13: Early voting notification 20 days before (ELEITORES DOENTES INTERNADOS - TODAY)
        # elections.append((datetime.today() + timedelta(days=20), False, "20 days exact", "Test: Exact 20 days - Early Voting Today"))
        
        # TEST 14: Early voting notification 15 days before (EM MOBILIDADE - TOMORROW)
        # elections.append((datetime.today() + timedelta(days=15), False, "15 days exact", "Test: Exact 15 days - Early Voting Tomorrow"))
        
        # TEST 15: Early voting notification 14 days before (EM MOBILIDADE - TODAY)
        # elections.append((datetime.today() + timedelta(days=14), False, "14 days exact", "Test: Exact 14 days - Early Voting Today"))
        
        # TEST 16: Early voting notification 13 days before (ELEITORES DESLOCADOS - TOMORROW)
        # elections.append((datetime.today() + timedelta(days=13), False, "13 days exact", "Test: Exact 13 days - Early Voting Tomorrow"))
        
        # TEST 17: Early voting notification 12 days before (ELEITORES DESLOCADOS - TODAY)
        # elections.append((datetime.today() + timedelta(days=12), False, "12 days exact", "Test: Exact 12 days - Early Voting Today"))
        
        # TEST 18: Election day notification - TOMORROW (1 day before)
        # elections.append((datetime.today() + timedelta(days=1), False, "1 day exact", "Test: Exact 1 day - Election Tomorrow"))
        
        # TEST 19: Election day notification - TODAY (0 days before)
        # elections.append((datetime.today(), False, "today exact", "Test: Exact 0 days - Election Today"))
        
        # TEST 20: Compare approximate vs exact at same offset
        # At 15 days: Approximate should get GENERIC notification, Exact should get EARLY VOTING notification
        # elections.append((datetime.today() + timedelta(days=15), True, "março", "Test: Approximate 15 days"))
        # elections.append((datetime.today() + timedelta(days=15), False, "15 days exact", "Test: Exact 15 days"))
        
        # TEST 21: No notification day for exact elections (e.g., 10 days before)
        # Exact elections should NOT notify at 10, 8, 6, 5, 4, 3, 2 days (those are approximate-only)
        # elections.append((datetime.today() + timedelta(days=10), False, "10 days exact", "Test: Exact 10 days - Should NOT notify"))

        # Check for elections in target range
        the_notification(elections)

        if parsing_errors:
            error_msg = f"Failed to parse {len(parsing_errors)} dates:\n" + "\n".join(parsing_errors) + "\n" + "https://www.cne.pt/content/calendario"
            send_notification("Parsing Errors", error_msg)

    except requests.RequestException as e:
        send_notification("Connection Error", f"Failed to access CNE website: {str(e)}")
    except Exception as e:
        send_notification("System Error", f"Unexpected error: {str(e)}")

def the_notification(elections):
    today = datetime.today().date()
    
    # --- Generic Notification Setup ---
    # Standard offsets for all elections
    standard_generic_offsets = [32, 27, 22]
    # Additional offsets ONLY for approximate elections (since we don't know exact date)
    approximate_additional_offsets = [21, 15, 14, 13, 12, 10, 8, 6, 5, 4, 3, 2, 1]
    
    generic_notifications = {}
    
    for election_date, is_approx, original_str, etype in elections:
        diff = (election_date.date() - today).days
        
        # For approximate dates, also check if we're inside the month(s)
        if is_approx:
            # Check if today is within the election month/range
            if election_date.year == today.year and election_date.month == today.month:
                # We're inside the approximate month - send daily alert
                date_display = format_election_date(election_date, is_approx, original_str)
                message = (
                    f"CRITICAL: Election THIS MONTH (exact date unknown):\n"
                    f"{date_display} {election_date.year} - {etype}\n"
                    "| Check CNE website for exact date\n"
                    "https://www.cne.pt/content/calendario"
                )
                send_notification("Election This Month Alert", message)
            
            # Also handle month ranges (e.g., "setembro/outubro")
            if '/' in original_str:
                # Parse out both months
                months_in_range = []
                for month_name, month_num in MONTHS.items():
                    if month_name in original_str.lower():
                        months_in_range.append(month_num)
                
                # Check if current month is in the range
                if today.month in months_in_range and election_date.year == today.year:
                    date_display = format_election_date(election_date, is_approx, original_str)
                    message = (
                        f"CRITICAL: Election THIS MONTH (exact date unknown):\n"
                        f"{date_display} {election_date.year} - {etype}\n"
                        "| Check CNE website for exact date\n"
                        "https://www.cne.pt/content/calendario"
                    )
                    send_notification("Election This Month Alert", message)
        
        # Determine which offsets apply to this election
        if is_approx:
            # Approximate elections get ALL offsets (more frequent warnings)
            applicable_offsets = standard_generic_offsets + approximate_additional_offsets
        else:
            # Exact date elections only get standard offsets
            applicable_offsets = standard_generic_offsets
        
        # Generic notifications at specific day offsets
        if diff in applicable_offsets:
            generic_notifications.setdefault(diff, []).append((election_date, is_approx, original_str, etype))
    
    # Print scheduled generic notifications
    for offset, elems in generic_notifications.items():
        for elec_date, is_approx, orig_str, _ in elems:
            notif_date = elec_date - timedelta(days=offset)
            approx_str = " (approximate)" if is_approx else ""
            print(f"Generic notification for election on {elec_date.strftime('%d/%m/%Y')}{approx_str} scheduled on {notif_date.strftime('%d/%m/%Y')}")
    
    # Send generic notifications
    for offset, elems in generic_notifications.items():
        if elems:
            message_lines = []
            for ed, is_approx, orig_str, etype in elems:
                date_display = format_election_date(ed, is_approx, orig_str)
                message_lines.append(f"{date_display} {ed.year} - {etype}")
            
            message = (
                "CRITICAL: Upcoming elections detected:\n" +
                "\n".join(message_lines) +
                "\n| Check if you need registration for early voting\n" +
                "https://www.cne.pt/content/calendario"
            )
            send_notification("Election Alert", message)
    
    # --- Early Voting and Election Day Notifications ---
    # Only for elections with exact dates (not approximate)
    early_voting_categories = {
        "EM MOBILIDADE": {"start": 14, "end": 10},
        "ELEITORES DOENTES INTERNADOS": {"start": 20, "end": 20},
        "ELEITORES DESLOCADOS NO ESTRANGEIRO": {"start": 12, "end": 10}
    }
    
    for election_date, is_approx, original_str, etype in elections:
        # Skip approximate dates for early voting notifications
        if is_approx:
            continue
            
        diff = (election_date.date() - today).days
        
        # Early voting notifications
        for category, period in early_voting_categories.items():
            start = period["start"]
            end = period["end"]
            
            if diff == start + 1:
                message = (
                    f"CRITICAL: Sign up for early voting TOMORROW if {category}:\n" +
                    f"Election on {election_date.strftime('%d/%m/%Y')} - {etype}\n" +
                    "| https://www.cne.pt/content/calendario | early voting dates: "
                    "https://www.portaldoeleitor.pt/pt/Eleitor/VotarAntecipadamente/Pages/default.aspx"
                )
                send_notification("Early Voting Alert", message)
            elif start >= diff >= end:
                message = (
                    f"CRITICAL: Sign up for early voting TODAY if {category}:\n" +
                    f"Election on {election_date.strftime('%d/%m/%Y')} - {etype}\n" +
                    "| https://www.cne.pt/content/calendario | early voting dates: "
                    "https://www.portaldoeleitor.pt/pt/Eleitor/VotarAntecipadamente/Pages/default.aspx"
                )
                send_notification("Early Voting Alert", message)
        
        # Election day notifications
        if diff == 0:
            message = (
                f"Election day TODAY for: {election_date.strftime('%d/%m/%Y')} - {etype}\n" +
                "| https://www.cne.pt/content/calendario"
            )
            send_notification("Election Day Alert", message)
        elif diff == 1:
            message = (
                f"Election day TOMORROW for: {election_date.strftime('%d/%m/%Y')} - {etype}\n" +
                "| https://www.cne.pt/content/calendario"
            )
            send_notification("Election Day Alert", message)

if __name__ == "__main__":
    check_elections()