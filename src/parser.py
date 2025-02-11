import csv
from bs4 import BeautifulSoup

def parse_html_table_to_csv(input_file, lectures_output_file, modules_output_file):
    with open(input_file, 'r', encoding='utf-8') as file:
        html_content = file.read()
    
    soup = BeautifulSoup(html_content, 'html.parser')
    table = soup.find('tbody')
    
    if not table:
        print("No table found in the input file.")
        return
    
    rows = table.find_all('tr')
    if len(rows) < 2:
        print("Not enough rows in the table to process.")
        return
    
    # Get headers from the first row
    headers = [header.get_text(strip=True) for header in rows[0].find_all('th')]
    
    lectures_data = []
    # modules_dict maps module code to a dictionary with venues, campuses, and offered values.
    modules_dict = {}  # key: module code, value: dict with keys 'venues', 'campuses', and 'offered'
    
    # Process each data row (skipping header row)
    for row in rows[1:]:
        cells = row.find_all(['td', 'th'])
        # Get the text for each cell (using "\n" as separator for multi-line cells)
        cell_texts = [cell.get_text("\n", strip=True) for cell in cells]
        
        # Remove spaces from module code
        cell_texts[0] = cell_texts[0].replace(" ", "")
        
        # Assuming the columns are in order:
        # 0: Module, 1: Offered, 2: Group, 3: Language,
        # 4: Activity, 5: Day, 6: Time, 7: Venue, 8: Campus, 9: Study Prog
        # Some cells may contain multiple lines separated by "\n", so we split:
        activities = cell_texts[4].split("\n")
        days = cell_texts[5].split("\n")
        times = cell_texts[6].split("\n")
        venues = cell_texts[7].split("\n")
        
        # Pad lists in case they are not the same length.
        max_items = max(len(activities), len(days), len(times), len(venues))
        activities += [""] * (max_items - len(activities))
        days += [""] * (max_items - len(days))
        times += [""] * (max_items - len(times))
        venues += [""] * (max_items - len(venues))
        
        # Process each lecture occurrence for this row.
        for i in range(max_items):
            # Create a lecture entry.
            # Take the first four columns as is, then the i-th value from activities, days, times, venues,
            # then append the rest of the columns (if any).
            lecture_entry = cell_texts[:4] + [activities[i], days[i], times[i], venues[i]] + cell_texts[8:]
            lectures_data.append(lecture_entry)
            
            # Process module information:
            module_code = cell_texts[0].strip()
            offered = cell_texts[1].strip()  # Offered field is in column 1.
            venue = venues[i].strip()         # Venue from the current lecture occurrence.
            campus = cell_texts[8].strip()      # Campus from column 8.
            
            # Initialize entry in modules_dict if not present.
            if module_code not in modules_dict:
                modules_dict[module_code] = {
                    'venues': set(),
                    'campuses': set(),
                    'offered': set()
                }
            # Add offered value (if not empty)
            if offered:
                modules_dict[module_code]['offered'].add(offered)
            if venue:
                modules_dict[module_code]['venues'].add(venue)
            if campus:
                modules_dict[module_code]['campuses'].add(campus)
    
    # Write lectures CSV (similar to your original output)
    with open(lectures_output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(lectures_data)
    print(f"Lectures data successfully written to {lectures_output_file}")
    
    # Write modules CSV – output: Module, Venues, Campuses, Offered
    with open(modules_output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Module', 'Venues', 'Campuses', 'Offered'])
        for module_code, info in modules_dict.items():
            venues_joined = "; ".join(sorted(info['venues']))
            campuses_joined = "; ".join(sorted(info['campuses']))
            offered_joined = "; ".join(sorted(info['offered']))
            writer.writerow([module_code, venues_joined, campuses_joined, offered_joined])
    print(f"Modules data successfully written to {modules_output_file}")

# Example usage:
parse_html_table_to_csv('data/TUKS_TIMETABLE_DATA.txt', 'lectures.csv', 'modules.csv')