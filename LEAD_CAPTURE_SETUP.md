# Lead Capture System - Configuration Guide

## Environment Variables Setup

Configure these in Firebase Console → Functions → Environment variables (or use Firebase CLI):

### Required for Email (SendGrid)
```bash
SENDGRID_API_KEY=SG.your_sendgrid_api_key_here
SENDGRID_FROM=noreply@jobscaffold.com
```

### Optional: Mailchimp Integration
```bash
MAILCHIMP_API_KEY=your_mailchimp_api_key
MAILCHIMP_LIST_ID=your_audience_list_id
MAILCHIMP_SERVER_PREFIX=us1  # or your server prefix (e.g., us6, us19)
```

### Optional: Slack Notifications
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Optional: Weekly Email Summary
```bash
ADMIN_EMAILS=admin@jobscaffold.com,manager@jobscaffold.com
```

## Firebase CLI Configuration

Alternatively, use Firebase CLI:

```powershell
# SendGrid
firebase functions:config:set sendgrid.api_key="SG.your_key"
firebase functions:config:set sendgrid.from="noreply@jobscaffold.com"

# Mailchimp
firebase functions:config:set mailchimp.api_key="your_key"
firebase functions:config:set mailchimp.list_id="your_list_id"
firebase functions:config:set mailchimp.server_prefix="us1"

# Slack
firebase functions:config:set slack.webhook_url="https://hooks.slack.com/..."

# Admin emails (comma-separated)
firebase functions:config:set admin.emails="admin@jobscaffold.com,manager@jobscaffold.com"

# Deploy after config changes
firebase deploy --only functions
```

## Features

### 1. Instant Lead Capture
- Footer form on https://jobscaffold.com
- Rate-limited (1 per email)
- Stores in Firestore `leads` collection

### 2. Automated Welcome Email (SendGrid)
- Triggers on new lead
- Sends branded welcome message
- Configurable template

### 3. Mailchimp Sync
- Auto-adds to your email list
- Tags: `website_lead`
- Merge field: `SOURCE`

### 4. Slack Notifications
- Real-time alerts to your team
- Shows email and source
- Emoji formatting

### 5. Weekly Summary Email
- Runs every Monday at 9 AM (timezone: function region)
- Sent to all `ADMIN_EMAILS`
- Includes:
  - Total leads for the week
  - Breakdown by source
  - Full lead list

### 6. Admin Panel
- Access: https://jobscaffold.com/leads_admin
- Requires authentication
- Features:
  - View all leads
  - Export to CSV
  - Refresh data

## Setup Checklist

- [ ] Configure SendGrid API key and from address
- [ ] (Optional) Set up Mailchimp API key and list ID
- [ ] (Optional) Create Slack incoming webhook
- [ ] (Optional) Add admin emails for weekly summaries
- [ ] Deploy functions: `firebase deploy --only functions`
- [ ] Test lead submission on live site
- [ ] Verify email/Slack/Mailchimp integrations

## Testing

1. Visit https://jobscaffold.com
2. Scroll to footer
3. Enter test email
4. Check:
   - Firestore `leads` collection
   - SendGrid activity
   - Mailchimp audience
   - Slack channel
   - Function logs: `firebase functions:log`

## Monitoring

View function logs:
```powershell
firebase functions:log
```

Filter by function:
```powershell
firebase functions:log --only onLeadCreated
firebase functions:log --only weeklyLeadSummary
```

## Troubleshooting

**No welcome email sent?**
- Check SendGrid config: `firebase functions:config:get`
- Verify API key is valid
- Check SendGrid dashboard for errors

**Mailchimp not syncing?**
- Verify API key, list ID, and server prefix
- Check function logs for errors
- Ensure list exists and API key has write permissions

**Weekly summary not running?**
- Check Cloud Scheduler in Firebase Console
- Verify `ADMIN_EMAILS` is set
- Check function logs on Monday morning

**Slack notifications missing?**
- Test webhook URL with curl
- Verify webhook is for the correct channel
- Check function logs for errors
