# Setup Guide — Entra ID IAM Governance Pipeline

## Requirements

| Requirement | Details |
|-------------|---------|
| Azure Account | Free / Azure for Students |
| Entra ID Tier | Free or P1 (P2 NOT required) |
| PowerShell | 5.1 or later |
| Azure Subscription | Needed for Logic Apps + Sentinel |

## Step-by-Step Setup

### 1. Create Resource Group
- Portal → Resource Groups → Create
- Name: `rg-iam-pipeline`
- Region: Nearest to you

### 2. Register App in Entra ID
- Entra ID → App registrations → New registration
- Name: `IAMGovernancePipeline`
- Single tenant

### 3. Add API Permissions
Add these **Application permissions** under Microsoft Graph:
- `User.ReadWrite.All`
- `Group.ReadWrite.All`
- `AuditLog.Read.All`
- `Directory.Read.All`

Click **Grant admin consent**.

### 4. Create Client Secret
- Certificates & secrets → New client secret
- Copy the **Value** immediately

### 5. Update Scripts
Open both `.ps1` files and replace:
```
YOUR_TENANT_ID    → your actual tenant ID
YOUR_CLIENT_ID    → your actual client ID
YOUR_SECRET_VALUE → your actual secret
```

### 6. Run Scripts
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
.\scripts\stale-account-detector.ps1
.\scripts\group-membership-audit.ps1
```

### 7. Create Logic App
- Azure → Logic Apps → Create (Consumption)
- Build: Recurrence → Get Token → Parse Token → Get Users → Send Email

### 8. Stream Logs to Sentinel
- Entra ID → Diagnostic Settings → Add
- Check: AuditLogs, SignInLogs
- Destination: Log Analytics workspace

### 9. Set Up Sentinel
- Add Sentinel to your Log Analytics workspace
- Install Microsoft Entra ID connector from Content Hub
- Import KQL rules from `sentinel/` folder

## Cost Estimate

| Service | Cost |
|---------|------|
| Logic Apps (Consumption) | ~$0.01/month for lab use |
| Log Analytics | Free for first 5GB/day |
| Microsoft Sentinel | Free trial / minimal for lab |
| Entra ID Free/P1 | Free (dev tenant) |

**Total estimated cost: < $1/month for a lab environment**
