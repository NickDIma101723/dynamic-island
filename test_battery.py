import subprocess
import re

def get_battery():
    try:
        output = subprocess.check_output(['ioreg', '-c', 'AppleDeviceManagementHIDEventService', '-r', '-l'], text=True)
        # Look for "BatteryPercent" or "BatteryLevel" etc
        matches = re.finditer(r'"BatteryPercent"\s*=\s*(\d+)', output)
        for m in matches:
            print("Found battery:", m.group(1))
            
        print("Raw dump length:", len(output))
        if len(output) > 0:
            lines = [l.strip() for l in output.split('\n') if 'Battery' in l or 'Level' in l or 'Charge' in l]
            for l in lines:
                print(l)
    except Exception as e:
        print(e)
get_battery()
