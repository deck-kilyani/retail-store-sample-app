# SSL Certificate Monitoring Script
# This script monitors DNS propagation and certificate status

Write-Host "=== SSL Certificate Setup Monitor ===" -ForegroundColor Green
Write-Host "Domain: tastydrive.store" -ForegroundColor Yellow
Write-Host "Load Balancer: k8s-ingressn-ingressn-20b823d43b-288c381c05803223.elb.us-west-2.amazonaws.com" -ForegroundColor Yellow
Write-Host ""

$domain = "tastydrive.store"
$maxAttempts = 60  # Monitor for 30 minutes (60 attempts * 30 seconds)
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "[$attempt/$maxAttempts] Checking DNS and certificate status..." -ForegroundColor Cyan
    
    # Check DNS resolution
    try {
        $dnsResult = Resolve-DnsName $domain -Type A -ErrorAction SilentlyContinue
        if ($dnsResult) {
            Write-Host "✅ DNS Resolution: SUCCESS" -ForegroundColor Green
            Write-Host "   Resolved to: $($dnsResult.IPAddress)" -ForegroundColor White
            $dnsWorking = $true
        } else {
            Write-Host "❌ DNS Resolution: Not yet propagated" -ForegroundColor Red
            $dnsWorking = $false
        }
    } catch {
        Write-Host "❌ DNS Resolution: Not yet propagated" -ForegroundColor Red
        $dnsWorking = $false
    }
    
    # Check certificate status
    try {
        $certStatus = kubectl get certificate tastydrive-store-tls -n retail-store -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>$null
        if ($certStatus -eq "True") {
            Write-Host "✅ Certificate Status: READY" -ForegroundColor Green
            $certReady = $true
        } else {
            Write-Host "⏳ Certificate Status: Pending" -ForegroundColor Yellow
            $certReady = $false
        }
    } catch {
        Write-Host "⏳ Certificate Status: Pending" -ForegroundColor Yellow
        $certReady = $false
    }
    
    # Check challenge status if certificate not ready
    if (-not $certReady) {
        try {
            $challengeStatus = kubectl get challenges -n retail-store -o jsonpath='{.items[0].status.state}' 2>$null
            if ($challengeStatus) {
                Write-Host "   Challenge State: $challengeStatus" -ForegroundColor White
            }
        } catch {
            # Ignore challenge check errors
        }
    }
    
    # If both DNS and certificate are ready, we're done
    if ($dnsWorking -and $certReady) {
        Write-Host ""
        Write-Host "🎉 SUCCESS! Domain and SSL certificate are ready!" -ForegroundColor Green
        Write-Host "✅ DNS is resolving correctly" -ForegroundColor Green
        Write-Host "✅ SSL certificate is issued and ready" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now access your application at:" -ForegroundColor Yellow
        Write-Host "https://$domain" -ForegroundColor White
        Write-Host ""
        break
    }
    
    # Wait 30 seconds before next check
    if ($attempt -lt $maxAttempts) {
        Write-Host "   Waiting 30 seconds before next check..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
        Write-Host ""
    }
}

if ($attempt -eq $maxAttempts) {
    Write-Host ""
    Write-Host "⚠️  Monitoring timeout reached (30 minutes)" -ForegroundColor Yellow
    Write-Host "DNS propagation can sometimes take up to 48 hours." -ForegroundColor White
    Write-Host "You can continue monitoring manually with:" -ForegroundColor White
    Write-Host "kubectl get certificates -n retail-store" -ForegroundColor Cyan
}