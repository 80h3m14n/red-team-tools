# Usage: ping_sweep.ps1 -SubNet "192.168.1"

param([string]$SubNet)

$ips = 1..254 | ForEach-Object { "$SubNet.$_" }
$ps = $ips | ForEach-Object { (New-Object Net.NetworkInformation.Ping).SendPingAsync($_, 250) }
[Threading.Tasks.Task]::WaitAll($ps)

$ps.Result | Where-Object { $_.Status -eq 'Success' } | Select-Object Address, RoundtripTime   