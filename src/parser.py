import csv
from bs4 import BeautifulSoup

def parse_html_table_to_csv(input_file, output_file):
    with open(input_file, 'r') as file:
        html_content = file.read()
    
    soup = BeautifulSoup(html_content, 'html.parser')
    table = soup.find('tbody')
    
    if not table:
        print("No table found in the input file.")
        return
    
    rows = table.find_all('tr')
    
    headers = [header.get_text(strip=True) for header in rows[0].find_all('th')]
    data = []
    
    for row in rows[1:]:
        cells = row.find_all(['td', 'th'])
        cell_texts = [cell.get_text("\n", strip=True) for cell in cells]
        
        activities = cell_texts[4].split("\n")  # Activity column
        days = cell_texts[5].split("\n")       # Day column
        times = cell_texts[6].split("\n")      # Time column
        venues = cell_texts[7].split("\n")     # Venue column

        max_activities = max(len(activities), len(days), len(times), len(venues))
        activities += [""] * (max_activities - len(activities))
        days += [""] * (max_activities - len(days))
        times += [""] * (max_activities - len(times))
        venues += [""] * (max_activities - len(venues))

        for i in range(max_activities):
            entry = cell_texts[:4] + [activities[i], days[i], times[i], venues[i]] + cell_texts[8:]
            data.append(entry)
    
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(data)

    print(f"Data successfully written to {output_file}")

parse_html_table_to_csv('data/TUKS_TIMETABLE_DATA.txt', 'output.csv')