import requests
import re
from datetime import datetime, timedelta
import subprocess
from bs4 import BeautifulSoup

MONTHS = {
    'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4,
    'maio': 5, 'junho': 6, 'julho': 7, 'agosto': 8,
    'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12
}

def send_notification(subject, body):
    """Send critical desktop notification"""
    try:
        subprocess.run(["notify-send", "-u", "critical", subject, body], check=True)
        print(f"Notification sent: {subject}")
    except Exception as e:
        print(f"Failed to send notification: {e}")

def parse_date(date_str, year):
    """Parse Portuguese date string with priority on day-month format"""
    original = date_str
    date_str = date_str.lower().strip()
    
    # First check for day-month pattern (e.g. "23 março")
    day_month = re.search(
        r'(\d{1,2})[\s\-/]*([a-záéíóúãõâêôç]+)', 
        date_str,
        flags=re.IGNORECASE
    )
    if day_month:
        try:
            day = int(day_month.group(1))
            month_str = day_month.group(2).strip()
            # Match full month name with Portuguese characters
            for month_name, month_num in MONTHS.items():
                if month_name.startswith(month_str):
                    return datetime(year, month_num, day)
        except (ValueError, KeyError):
            pass
    
    # Then handle month ranges (e.g. "setembro/outubro")
    if '/' in date_str:
        months = [m.strip() for m in date_str.split('/')]
        for month in months:
            for month_name, month_num in MONTHS.items():
                if month_name.startswith(month):
                    return datetime(year, month_num, 15)  # Mid-month default
    
    # Then single month names (e.g. "novembro")
    for month_name, month_num in MONTHS.items():
        if month_name in date_str:
            return datetime(year, month_num, 15)
    
    print(f"Failed to parse: {original}")
    return None

def check_elections():
    try:
        today = datetime.today()
        start_date = today + timedelta(weeks=2)
        end_date = today + timedelta(days=60)
        print(f"Today: {today.strftime('%Y-%m-%d')}")
        print(f"Checking range: {start_date.strftime('%d/%m/%Y')} - {end_date.strftime('%d/%m/%Y')}\n")

        # Scrape election data
        url = 'https://www.cne.pt/content/calendario'
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        table = soup.find('table')
        
        if not table:
            send_notification("Scraping Error", "No calendar table found")
            return

        elections = []
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
                parsed_date = parse_date(raw_date, year)
                
                if parsed_date:
                    elections.append((parsed_date, etype))
                    print(f"Parsed as: {parsed_date.strftime('%d/%m/%Y')}\n")
                else:
                    parsing_errors.append(raw_date)
            except ValueError:
                parsing_errors.append(raw_date)
                print(f"Invalid year: {year_str}\n")

        # UNIT TESTS

        # Generic Notification: Election exactly 32 days away
        # elections.append((datetime.today() + timedelta(days=32), "Generic Election Test"))

        # Generic Notification: Election exactly 27 days away
        #elections.append((datetime.today() + timedelta(days=27), "Generic Election Test"))

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

        # Election Day Notification for today (diff == 0)
        # elections.append((datetime.today(), "Election Day Test"))

        # Election Day Notification for tomorrow (diff == 1)
        # elections.append((datetime.today() + timedelta(days=1), "Election Day Test"))

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
    generic_offsets = [32, 27, 22]  # days before election to send generic notification
    generic_notifications = {}  # key: offset, value: list of elections
    for election_date, etype in elections:
        diff = (election_date.date() - today).days
        if diff in generic_offsets:
            generic_notifications.setdefault(diff, []).append((election_date, etype))
    
    # CHANGED: Print in terminal all scheduled generic notification dates
    for offset, elems in generic_notifications.items():
        for elec_date, _ in elems:
            notif_date = elec_date - timedelta(days=offset)
            print(f"Generic notification for election on {elec_date.strftime('%d/%m/%Y')} scheduled on {notif_date.strftime('%d/%m/%Y')}")
    
    # CHANGED: If today is one of the generic notification days, send the notification
    for offset, elems in generic_notifications.items():
        # Since diff==offset means today is exactly election_date - offset
        if elems:
            message_lines = [f"{ed.strftime('%d/%m/%Y')} - {etype}" for ed, etype in elems]
            message = (
                "CRITICAL: Upcoming elections detected:\n" +
                "\n".join(message_lines) +
                "\n| Check if you need registration for early voting\n" +
                "https://www.cne.pt/content/calendario"
            )
            send_notification("Election Alert", message)
    
    # --- Early Voting Notifications ---
    # CHANGED: Define early voting notification schedules for each category
    early_voting_categories = {
        "EM MOBILIDADE": {"start": 14, "end": 10},
        "ELEITORES DOENTES INTERNADOS": {"start": 20, "end": 20},
        "ELEITORES DESLOCADOS NO ESTRANGEIRO": {"start": 12, "end": 10}
    }
    
    for election_date, _ in elections:
        diff = (election_date.date() - today).days
        for category, period in early_voting_categories.items():
            start = period["start"]
            end = period["end"]
            # CHANGED: If diff equals start+1, then early voting starts TOMORROW
            if diff == start + 1:
                message = (
                    f"CRITICAL: Sign up for early voting TOMORROW if {category}:\n" +
                    f"Election on {election_date.strftime('%d/%m/%Y')}\n" +
                    "| https://www.cne.pt/content/calendario | early voting dates: "
                    "https://www.portaldoeleitor.pt/pt/Eleitor/VotarAntecipadamente/Pages/default.aspx"
                )
                send_notification("Early Voting Alert", message)
            # CHANGED: If today is within the early voting period, notify for TODAY
            elif start >= diff >= end:
                message = (
                    f"CRITICAL: Sign up for early voting TODAY if {category}:\n" +
                    f"Election on {election_date.strftime('%d/%m/%Y')}\n" +
                    "| https://www.cne.pt/content/calendario | early voting dates: "
                    "https://www.portaldoeleitor.pt/pt/Eleitor/VotarAntecipadamente/Pages/default.aspx"
                )
                send_notification("Early Voting Alert", message)

    # --- Election Day Notifications ---  ### ADDED SECTION
    for election_date, etype in elections:
        diff = (election_date.date() - today).days
        if diff == 0:
            # If the election is today
            message = (
                f"Election day TODAY for: {election_date.strftime('%d/%m/%Y')} - {etype}\n" +
                "| https://www.cne.pt/content/calendario"
            )
            send_notification("Election Day Alert", message)
        elif diff == 1:
            # If the election is tomorrow (notify TOMORROW)
            message = (
                f"Election day TOMORROW for: {election_date.strftime('%d/%m/%Y')} - {etype}\n" +
                "| https://www.cne.pt/content/calendario"
            )
            send_notification("Election Day Alert", message)

if __name__ == "__main__":
    check_elections()