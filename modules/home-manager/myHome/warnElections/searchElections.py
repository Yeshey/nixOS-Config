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

        # Generic Notification: Election exactly 32 days away
        # elections.append((datetime.today() + timedelta(days=32), "Generic Election Test"))

        # Generic Notification: Election exactly 27 days away
        # elections.append((datetime.today() + timedelta(days=27), "Generic Election Test"))

        # Generic Notification: Election exactly 22 days away
        # elections.append((datetime.today() + timedelta(days=22), "Generic Election Test"))

        # Early Voting (EM MOBILIDADE): "TOMORROW" trigger – election 15 days away (since 14+1)
        # elections.append((datetime.today() + timedelta(days=15), "EM MOBILIDADE Test"))

        # Early Voting (EM MOBILIDADE): "TODAY" trigger – election 14 days away
        # elections.append((datetime.today() + timedelta(days=14), "EM MOBILIDADE Test"))

        # Early Voting (ELEITORES DOENTES INTERNADOS): "TOMORROW" trigger – election 21 days away (20+1)
        # elections.append((datetime.today() + timedelta(days=21), "ELEITORES DOENTES INTERNADOS Test"))

        # Early Voting (ELEITORES DOENTES INTERNADOS): "TODAY" trigger – election 20 days away
        # elections.append((datetime.today() + timedelta(days=20), "ELEITORES DOENTES INTERNADOS Test"))

        # Early Voting (ELEITORES DESLOCADOS NO ESTRANGEIRO): "TOMORROW" trigger – election 13 days away (12+1)
        # elections.append((datetime.today() + timedelta(days=13), "ELEITORES DESLOCADOS NO ESTRANGEIRO Test"))

        # Early Voting (ELEITORES DESLOCADOS NO ESTRANGEIRO): "TODAY" trigger – election 12 days away
        #elections.append((datetime.today() + timedelta(days=12), "ELEITORES DESLOCADOS NO ESTRANGEIRO Test"))

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
    generic_offsets = [32, 27, 22]
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
        
        # Generic notifications at specific day offsets
        if diff in generic_offsets:
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