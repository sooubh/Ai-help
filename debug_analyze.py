import json
import os

try:
    if not os.path.exists('lib_analysis.json'):
        print("Error: lib_analysis.json not found")
        exit(1)
        
    with open('lib_analysis.json', 'r', encoding='utf-16-le') as f: # PowerShell redirection often uses UTF-16
        content = f.read()
        # Some versions of powershell add a BOM or use utf-16
except:
    try:
        with open('lib_analysis.json', 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        exit(1)

issues = []
for line in content.splitlines():
    line = line.strip()
    if line.startswith('{') and line.endswith('}'):
        try:
            issues.append(json.loads(line))
        except:
            pass

print(f"Total issues found: {len(issues)}")
for i, issue in enumerate(issues, 1):
    severity = issue.get('severity', 'UNKNOWN')
    code = issue.get('code', 'UNKNOWN')
    message = issue.get('message', 'UNKNOWN')
    location = issue.get('location', {})
    file = location.get('file', 'UNKNOWN')
    line = location.get('range', {}).get('start', {}).get('line', 'UNKNOWN')
    # Make path relative to project root for readability
    rel_file = os.path.relpath(file, os.getcwd()) if os.path.isabs(file) else file
    print(f"[{i}] {severity} - {code} at {rel_file}:{line}")
    print(f"    {message}")
