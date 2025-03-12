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
        start_date = today + timedelta(weeks=1)
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

        # Check for elections in target range
        upcoming = []
        for date, etype in elections:
            if start_date <= date <= end_date:
                upcoming.append(f"{date.strftime('%d/%m/%Y')} - {etype}")
        
        # Handle notifications
        if upcoming:
            message = "CRITICAL: Upcoming elections detected:\n" + "\n".join(upcoming) + "\n" + "| Check if you need registration for early voting" + "\n" + "https://www.cne.pt/content/calendario"
            send_notification("Election Alert", message)
        else:
            print("\nNo elections in target range")
            
        if parsing_errors:
            error_msg = f"Failed to parse {len(parsing_errors)} dates:\n" + "\n".join(parsing_errors) + "\n" + "https://www.cne.pt/content/calendario"
            send_notification("Parsing Errors", error_msg)

    except requests.RequestException as e:
        send_notification("Connection Error", f"Failed to access CNE website: {str(e)}")
    except Exception as e:
        send_notification("System Error", f"Unexpected error: {str(e)}")

if __name__ == "__main__":
    check_elections()