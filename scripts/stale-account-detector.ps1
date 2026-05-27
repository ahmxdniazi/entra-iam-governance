# =============================================================================
#  Stale Account Detector — Entra ID IAM Governance Pipeline
#  Author  : Muhammad Ahmad (niazi1199743gmail)
#  Purpose : Identify and optionally disable accounts with no recent sign-in
#            activity (based on account age > 30 days) using Microsoft Graph API
# =============================================================================

# ── CONFIG ────────────────────────────────────────────────────────────────────
$tenantId     = "YOUR_TENANT_ID"
$clientId     = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_SECRET_VALUE"
# ─────────────────────────────────────────────────────────────────────────────

# Get access token via client credentials flow
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}
$token   = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $body
$headers = @{ Authorization = "Bearer $($token.access_token)" }

# Fetch all users with selected fields
$uri   = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,accountEnabled,createdDateTime"
$users = Invoke-RestMethod -Uri $uri -Headers $headers

$staleUsers = @()
$cutoff     = (Get-Date).AddDays(-30)

foreach ($user in $users.value) {
    $lastSignIn = $user.createdDateTime
    if (-not $lastSignIn -or [datetime]$lastSignIn -lt $cutoff) {
        $staleUsers += $user
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   ENTRA ID — STALE ACCOUNT DETECTOR       " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All Users in Tenant:" -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow

foreach ($user in $users.value) {
    if ($user.accountEnabled) {
        $status = "Active"
        $color  = "Green"
    } else {
        $status = "Disabled"
        $color  = "Red"
    }
    Write-Host "  Name    : $($user.displayName)"
    Write-Host "  UPN     : $($user.userPrincipalName)"
    Write-Host "  Created : $($user.createdDateTime)"
    Write-Host "  Status  : $status" -ForegroundColor $color
    Write-Host "  ----------------------------------------"
}

Write-Host ""
Write-Host "Total users found: $($users.value.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Governance candidates (accounts older than 30 days): $($staleUsers.Count)" -ForegroundColor Yellow

if ($staleUsers.Count -gt 0) {
    $confirm = Read-Host "Disable these $($staleUsers.Count) accounts? (yes/no)"
    if ($confirm -eq "yes") {
        foreach ($user in $staleUsers) {
            $patchBody = @{ accountEnabled = $false } | ConvertTo-Json
            Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)" `
                -Method PATCH -Headers $headers -Body $patchBody -ContentType "application/json"
            Write-Host "Disabled: $($user.displayName)" -ForegroundColor Red
        }
        Write-Host "Done. $($staleUsers.Count) accounts disabled." -ForegroundColor Green
    } else {
        Write-Host "No changes made." -ForegroundColor Cyan
    }
}
