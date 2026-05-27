# =============================================================================
#  Group Membership Audit — Entra ID IAM Governance Pipeline
#  Author  : Muhammad Ahmad (niazi1199743gmail)
#  Purpose : Enumerate all Entra ID groups and their members, flag empty groups,
#            and export a full audit report to CSV via Microsoft Graph API
# =============================================================================

# ── CONFIG ────────────────────────────────────────────────────────────────────
$tenantId     = "YOUR_TENANT_ID"
$clientId     = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_SECRET_VALUE"
$outputPath   = "group_membership_audit.csv"
# ─────────────────────────────────────────────────────────────────────────────

# Get access token
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}
$token   = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $body
$headers = @{ Authorization = "Bearer $($token.access_token)" }

# Get all groups
$groups = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups" -Headers $headers
$report = @()

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   ENTRA ID — GROUP MEMBERSHIP AUDIT       " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scanning $($groups.value.Count) groups..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow

foreach ($group in $groups.value) {
    $members = Invoke-RestMethod `
        -Uri "https://graph.microsoft.com/v1.0/groups/$($group.id)/members" `
        -Headers $headers

    if ($members.value.Count -eq 0) {
        $report += [PSCustomObject]@{
            GroupName  = $group.displayName
            GroupId    = $group.id
            MemberName = "(empty group)"
            MemberUPN  = ""
            MemberType = ""
            ReviewFlag = "EMPTY - consider deletion"
        }
        Write-Host "  Group  : $($group.displayName)" -ForegroundColor Cyan
        Write-Host "  Status : Empty" -ForegroundColor Red
        Write-Host "  ----------------------------------------"
    } else {
        foreach ($member in $members.value) {
            $report += [PSCustomObject]@{
                GroupName  = $group.displayName
                GroupId    = $group.id
                MemberName = $member.displayName
                MemberUPN  = $member.userPrincipalName
                MemberType = $member."@odata.type" -replace "#microsoft.graph.",""
                ReviewFlag = ""
            }
        }
        Write-Host "  Group   : $($group.displayName)" -ForegroundColor Cyan
        Write-Host "  Members : $($members.value.Count)" -ForegroundColor Green
        Write-Host "  ----------------------------------------"
    }
}

$report | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host ""
Write-Host "Report saved : $outputPath" -ForegroundColor Green
Write-Host "Total rows   : $($report.Count)" -ForegroundColor Cyan
Write-Host "Location     : $(Get-Location)\$outputPath" -ForegroundColor Cyan
