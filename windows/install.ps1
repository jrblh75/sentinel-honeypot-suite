# ShadowTrace Sentinel Installation Script for Windows
# © 2025 Brannon-Lee Hollis Jr.

# --- Setup folder ---
$honeypot = "$env:USERPROFILE\.honeypot"
New-Item -ItemType Directory -Force -Path $honeypot | Out-Null

# --- Encrypt sample secret data with Windows DPAPI ---
$realDataPath = Join-Path $honeypot "real_data.txt"
$encryptedDataPath = Join-Path $honeypot "real_data.encrypted"

@"
Confidential Data: Replace me with your secret.
"@ | Out-File -FilePath $realDataPath -Encoding utf8

Write-Host "🔒 Encrypting real data with Windows DPAPI..."
$secureBytes = [System.Security.Cryptography.ProtectedData]::Protect(
    [System.Text.Encoding]::UTF8.GetBytes((Get-Content $realDataPath -Raw)),
    $null,
    [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
[IO.File]::WriteAllBytes($encryptedDataPath, $secureBytes)
Remove-Item $realDataPath

# --- Honeypot trap script (PowerShell) ---
$trapScript = @"
# ShadowTrace Sentinel Honeypot Trap - PowerShell Script
\$ownerUUID = (Get-WmiObject Win32_ComputerSystemProduct).UUID
\$currentUUID = \$ownerUUID
\$ip = (Invoke-WebRequest -UseBasicParsing -Uri 'https://api.ipify.org').Content
\$time = Get-Date -Format 'yyyy-MM-dd_HH:mm:ss'
\$marker = 'RPT-ID-' + (Get-Random) + '-TRAP2025'
\$encryptedFile = '$encryptedDataPath'

function Decrypt-Data {
    param(\$file)
    try {
        \$encryptedBytes = [IO.File]::ReadAllBytes(\$file)
        \$decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
            \$encryptedBytes, \$null,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        return [System.Text.Encoding]::UTF8.GetString(\$decryptedBytes)
    } catch {
        return 'Error decrypting data'
    }
}

if (\$currentUUID -eq \$ownerUUID) {
    Write-Host '✅ Authorized - Decrypting real data:'
    \$data = Decrypt-Data -file \$encryptedFile
    Write-Output \$data
} else {
    Write-Host '⚠️ Unauthorized access detected'
    try {
        Invoke-WebRequest -Uri 'https://yourserver.com/log' -Method POST -Body @{
            uuid = \$currentUUID
            ip = \$ip
            time = \$time
            marker = \$marker
        } -UseBasicParsing -TimeoutSec 5 | Out-Null
    } catch {}

    Write-Output 'Fake Report: Q1: Up | Q2: Flat | Q3: Projected'
    Write-Output 'Marker: ' + \$marker
}
"@

$trapPath = Join-Path $honeypot "README_OPEN_ME.ps1"
Set-Content -Path $trapPath -Value $trapScript -Force

# --- Tamper watcher script (PowerShell) ---
$tamperScript = @"
# ShadowTrace Sentinel Tamper Watcher - PowerShell Script
\$watchFile = '$trapPath'
\$stateFile = '$honeypot\.watch_state'
\$logFile = '$honeypot\tamper.log'

if (-not (Test-Path \$stateFile)) {
    (Get-Item \$watchFile).LastWriteTime | Out-File \$stateFile
}

while (\$true) {
    \$newState = (Get-Item \$watchFile).LastWriteTime
    \$oldState = Get-Content \$stateFile

    if (\$newState -ne \$oldState) {
        \$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        "\$timestamp: File tampering or movement detected on \$watchFile" | Out-File -Append \$logFile

        # Email alert config
        \$smtpServer = 'smtp.gmail.com'
        \$smtpPort = 587
        \$smtpUser = '<your-email@gmail.com>'
        \$smtpPass = '<your-app-password>'
        \$to = '<recipient-email@gmail.com>'
        \$subject = 'ShadowTrace Sentinel Tamper Alert'
        \$body = "Tampering detected on file: \$watchFile at \$timestamp"

        try {
            Send-MailMessage -From \$smtpUser -To \$to -Subject \$subject -Body \$body `
                -SmtpServer \$smtpServer -Port \$smtpPort -UseSsl -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList \$smtpUser, (ConvertTo-SecureString \$smtpPass -AsPlainText -Force))
        } catch {
            Write-Output 'Failed to send email alert'
        }

        \$newState | Out-File \$stateFile
    }
    Start-Sleep -Seconds 10
}
"@

$tamperPath = Join-Path $honeypot "tamper_watch.ps1"
Set-Content -Path $tamperPath -Value $tamperScript -Force

# --- Python scripts ---

# PDF Fingerprint (pdf_fingerprint.py)
$pdfFingerprintScript = @'
#!/usr/bin/env python3
import sys, uuid, datetime
import pikepdf

def add_fingerprint(pdf_in, pdf_out):
    fingerprint_text = f"UUID:{uuid.uuid4()} Date:{datetime.datetime.utcnow().isoformat()}"
    pdf = pikepdf.open(pdf_in)
    pdf.docinfo["/Fingerprint"] = fingerprint_text
    pdf.save(pdf_out)
    print(f"Fingerprint added to {pdf_out} with text: {fingerprint_text}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: pdf_fingerprint.py input.pdf output.pdf")
        sys.exit(1)
    add_fingerprint(sys.argv[1], sys.argv[2])
'@
$pdfPath = Join-Path $honeypot "pdf_fingerprint.py"
Set-Content -Path $pdfPath -Value $pdfFingerprintScript -Force

# Zero-width Steganography Tool (zwsp_tool.py)
$zwspScript = @'
#!/usr/bin/env python3
ZWSP = "\u200B"
ZWNJ = "\u200C"
DEL = "\u200D"

def to_zw(txt):
    return "".join(ZWSP if b == "0" else ZWNJ for c in txt for b in format(ord(c), "08b")) + DEL

def from_zw(t):
    bits = "".join("0" if c == ZWSP else "1" for c in t if c in (ZWSP, ZWNJ))
    return "".join(chr(int(bits[i:i+8], 2)) for i in range(0, len(bits), 8))

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: embed <infile> <outfile> <message> | extract <file>")
        sys.exit(1)
    if sys.argv[1] == "embed":
        with open(sys.argv[2]) as f, open(sys.argv[3], "w") as out:
            content = f.read()
            out.write(content + to_zw(sys.argv[4]))
            print(f"✓ Embedded message into {sys.argv[3]}")
    elif sys.argv[1] == "extract":
        with open(sys.argv[2]) as f:
            text = f.read()
            zw = "".join(c for c in text if c in (ZWSP, ZWNJ, DEL))
            print("✓ Decoded:", from_zw(zw) if zw else "None")
    else:
        print("Invalid command.")
'@
$zwspPath = Join-Path $honeypot "zwsp_tool.py"
Set-Content -Path $zwspPath -Value $zwspScript -Force

# Leak Scanner (leak_scanner.py)
$leakScannerScript = @"
#!/usr/bin/env python3
import os, requests, datetime

KEY = os.getenv('BING_API_KEY')
PHRASE = 'RPT-ID-TRAP2025'
LOG = '$honeypot\leak_scan.log'
EMAIL = os.getenv('ALERT_EMAIL')
PASS = os.getenv('EMAIL_PASS')

def bing_scan():
    headers = {'Ocp-Apim-Subscription-Key': KEY}
    params = {'q': PHRASE}
    try:
        r = requests.get('https://api.bing.microsoft.com/v7.0/search', headers=headers, params=params)
        r.raise_for_status()
        return [v['url'] for v in r.json().get('webPages', {}).get('value', [])]
    except Exception as e:
        print('Bing API error:', e)
        return []

def scrape_fallback():
    import httpx
    from parsel import Selector
    r = httpx.get(f'https://www.bing.com/search?q={PHRASE}')
    sel = Selector(r.text)
    return [item.xpath('.//h2/a/@href').get() for item in sel.xpath('//li[@class="b_algo"]')]

def notify_email(links):
    if not EMAIL or not PASS or not links:
        return
    import yagmail
    try:
        yag = yagmail.SMTP(EMAIL, PASS)
        yag.send(to=EMAIL, subject='🚨 Honeypot Leak Detected', contents='\\n'.join(links))
        print('Email alert sent.')
    except Exception as e:
        print('Email send error:', e)

def main():
    links = []
    if KEY:
        links = bing_scan()
    if not links:
        links = scrape_fallback()
    if links:
        msg = f'{datetime.datetime.now()} FOUND:\\n' + '\\n'.join(links)
        with open(LOG, 'a') as f:
            f.write(msg + '\\n')
        print(msg)
        notify_email(links)
    else:
        print(f'{datetime.datetime.now()} ✓ No leaks found.')

if __name__ == '__main__':
    main()
"@
$leakScannerPath = Join-Path $honeypot "leak_scanner.py"
Set-Content -Path $leakScannerPath -Value $leakScannerScript -Force

# --- Flask Dashboard (dashboard.py) ---

$dashboardScript = @'
import os
from flask import Flask, render_template_string, request, redirect, url_for, flash
import subprocess
import threading

app = Flask(__name__)
app.secret_key = os.urandom(24)

HONEYPOT_DIR = os.path.expanduser("~\\.honeypot")
TAMPER_LOG = os.path.join(HONEYPOT_DIR, "tamper.log")
LEAK_SCAN_LOG = os.path.join(HONEYPOT_DIR, "leak_scan.log")
LEAK_SCANNER_SCRIPT = os.path.join(HONEYPOT_DIR, "leak_scanner.py")
PYTHON_EXE = "python"  # Adjust if needed

TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>ShadowTrace Sentinel Dashboard</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 1rem; background:#121212; color:#eee; }
    h1, h2 { color: #1db954; }
    textarea { width: 100%; height: 200px; background:#222; color:#eee; border:none; padding:10px; resize: vertical;}
    button { background:#1db954; color:#121212; border:none; padding:10px 20px; margin-top:10px; cursor:pointer; font-weight:bold; }
    button:hover { background:#17a34a; }
    .flash { color: #f44336; margin-bottom: 10px; }
  </style>
</head>
<body>
  <h1>ShadowTrace Sentinel Dashboard</h1>
  {% with messages = get_flashed_messages() %}
    {% if messages %}
      <div class="flash">{{ messages[0] }}</div>
    {% endif %}
  {% endwith %}

  <section>
    <h2>Tamper Log</h2>
    <textarea readonly>{{ tamper_log }}</textarea>
  </section>

  <section>
    <h2>Leak Scan Log</h2>
    <textarea readonly>{{ leak_log }}</textarea>
  </section>

  <section>
    <h2>Manual Leak Scan</h2>
    <form method="post" action="{{ url_for('run_leak_scan') }}">
      <button type="submit">Run Leak Scanner Now</button>
    </form>
  </section>
</body>
</html>
"""

def read_file(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return "No data or file not found."

def run_leak_scan_background():
    subprocess.Popen([PYTHON_EXE, LEAK_SCANNER_SCRIPT])

@app.route("/")
def index():
    tamper_log = read_file(TAMPER_LOG)
    leak_log = read_file(LEAK_SCAN_LOG)
    return render_template_string(TEMPLATE, tamper_log=tamper_log, leak_log=leak_log)

@app.route("/run-leak-scan", methods=["POST"])
def run_leak_scan():
    try:
        threading.Thread(target=run_leak_scan_background).start()
        flash("Leak scan started in background. Check logs shortly.")
    except Exception as e:
        flash(f"Error starting leak scan: {e}")
    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=False)
'@
$dashboardPath = Join-Path $honeypot "dashboard.py"
Set-Content -Path $dashboardPath -Value $dashboardScript -Force

# --- Install Python dependencies ---
Write-Host "⏳ Checking and installing Python dependencies..."
$pythonExe = "python"
$packages = @("pikepdf", "requests", "yagmail", "httpx", "parsel", "flask")

foreach ($pkg in $packages) {
    Write-Host "Checking $pkg..."
    $check = & $pythonExe -m pip show $pkg 2>$null
    if (-not $check) {
        Write-Host "Installing $pkg..."
        & $pythonExe -m pip install $pkg
    } else {
        Write-Host "$pkg already installed."
    }
}

# --- Register Scheduled Tasks ---

# Tamper Watcher Task (runs at logon, hidden)
$tamperTaskName = "ShadowTraceTamperWatcher"
$action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$tamperPath`""
$trigger1 = New-ScheduledTaskTrigger -AtLogOn
$settings1 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $tamperTaskName -Action $action1 -Trigger $trigger1 -Settings $settings1 -Force

# Leak Scanner Task (runs daily at 2AM)
$leakTaskName = "ShadowTraceLeakScanner"
$action2 = New-ScheduledTaskAction -Execute $pythonExe -Argument "`"$leakScannerPath`""
$trigger2 = New-ScheduledTaskTrigger -Daily -At 2am
$settings2 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $leakTaskName -Action $action2 -Trigger $trigger2 -Settings $settings2 -Force

Write-Host "✅ ShadowTrace Sentinel installed at $honeypot"
Write-Host "▶ Run trap: powershell.exe -File `"$trapPath`""
Write-Host "▶ Tamper watcher auto-runs at logon as scheduled task '$tamperTaskName'"
Write-Host "▶ Leak scanner runs daily at 2AM as scheduled task '$leakTaskName'"
Write-Host "▶ Run dashboard: python `"$dashboardPath`""
Write-Host ""
Write-Host "⚠️ IMPORTANT:"
Write-Host " - Configure SMTP credentials inside tamper_watch.ps1"
Write-Host " - Set environment variables BING_API_KEY, ALERT_EMAIL, EMAIL_PASS for leak scanner"