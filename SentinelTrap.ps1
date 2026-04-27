<#
.SYNOPSIS
    SentinelTrap - Active Defense & EDR Automation System
.DESCRIPTION
    Automated Host Intrusion Prevention System (HIPS) that monitors Windows Event Logs for RDP/SMB brute-force attacks.
    Integrates with AbuseIPDB for Threat Intelligence (OSINT) and dynamically updates Windows Firewall rules to isolate threats.
    Alerts are dispatched via Webhook to SOC channels.
.AUTHOR
    Desenvolvido por Arthur BRM
#>

# ==============================================================================
# CONFIGURATION (DO NOT COMMIT REAL KEYS)
# ==============================================================================
$API_KEY = "INSERT_YOUR_ABUSEIPDB_API_KEY_HERE"
$DISCORD_WEBHOOK = "INSERT_YOUR_DISCORD_WEBHOOK_URL_HERE"
$THRESHOLD = 3

Write-Host "--- SentinelTrap Engine: Active Monitoring Initiated ---" -ForegroundColor Cyan

while($true) {
    # 1. Log Ingestion & Parsing
    $Events = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 50 -ErrorAction SilentlyContinue

    if ($Events) {
        # 2. Heuristics & Regex Filtering (IPv4/IPv6 strictly)
        $Attacks = $Events | ForEach-Object { $_.Properties[19].Value } | Where-Object { 
            ($_ -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$") -or ($_ -match "^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$") -or ($_ -eq "::1")
        } | Group-Object | Where-Object { $_.Count -ge $THRESHOLD }

        foreach ($Attack in $Attacks) {
            $TargetIP = $Attack.Name
            
            # 3. Whitelisting (Fail-Safe against self-isolation)
            if ($TargetIP -eq "::1" -or $TargetIP -eq "127.0.0.1") { 
                Write-Host "[i] Local telemetry ($TargetIP) discarded. Fail-safe active." -ForegroundColor Gray
                continue 
            }

            Write-Host "[!] Threat Actor Identified: $TargetIP" -ForegroundColor Yellow

            try {
                # 4. OSINT Enrichment (AbuseIPDB)
                $Headers = @{"Key"=$API_KEY; "Accept"="application/json"}
                $Info = Invoke-RestMethod -Method Get -Uri "https://api.abuseipdb.com/api/v2/check?ipAddress=$TargetIP" -Headers $Headers -ErrorAction Stop
                $Score = $Info.data.abuseConfidenceScore

                # 5. Automated Remediation (Firewall Isolation)
                Write-Host "[*] Executing Firewall Containment for $TargetIP..." -ForegroundColor Red
                New-NetFirewallRule -DisplayName "SentinelTrap-BLOCK-$TargetIP" -Direction Inbound -Action Block -RemoteAddress $TargetIP -ErrorAction SilentlyContinue

                # 6. SOC Alert Dispatch
                $Payload = @{
                    embeds = @(@{
                        title = "🚨 Security Incident: Threat Contained"
                        color = 16711680
                        fields = @(
                            @{name="Attacker IP"; value=$TargetIP; inline=$true},
                            @{name="AbuseIPDB Score"; value="$Score%"; inline=$true},
                            @{name="Auth Failures"; value="$($Attack.Count)"; inline=$true},
                            @{name="Remediation"; value="Host isolated via Windows Defender Firewall."; inline=$false}
                        )
                    })
                } | ConvertTo-Json -Depth 4
                
                Invoke-RestMethod -Method Post -Uri $DISCORD_WEBHOOK -Body $Payload -ContentType "application/json"
                Write-Host "[OK] Telemetry dispatched to SOC." -ForegroundColor Green

            } catch {
                Write-Host "[X] API/Network Exception for $TargetIP : $_" -ForegroundColor Red
            }
        }
    }
    Start-Sleep -Seconds 15
}