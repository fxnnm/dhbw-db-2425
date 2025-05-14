import os
import sys

def check_indentation(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        for i, line in enumerate(lines):
            # Check for missing line breaks
            if i < len(lines) - 1:
                if line.strip() and not line.endswith('\n') and not lines[i+1].startswith(' '):
                    print(f"Line {i+1}: Missing line break")
                    print(f"Line {i+1}: {line.rstrip()}")
                    print(f"Line {i+2}: {lines[i+1].rstrip()}")
                    print()
            
            # Check for tab/space mix
            if '\t' in line and ' ' in line:
                print(f"Line {i+1}: Mixed tabs and spaces")
                print(f"Line {i+1}: {line.rstrip()}")
                print()

if __name__ == "__main__":
    # Check route.py
    route_path = r"c:\Users\finnm\Documents\HAUPTORDNER\Studium\Sem4\DB\dhbw-db-2425\api\routes\route.py"
    check_indentation(route_path)
    
    # Check helpers.py
    helpers_path = r"c:\Users\finnm\Documents\HAUPTORDNER\Studium\Sem4\DB\dhbw-db-2425\infrastructure\database\helpers\helpers.py"
    check_indentation(helpers_path)
