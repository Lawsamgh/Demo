# FileMaker Server Setup Guide

## Error 812: "Exceeded host's capacity"

This error occurs when FileMaker Server has reached its maximum connection limit. Here are the things to check:

### 1. FileMaker Server Connection Limits

**Check Server-Level Limits:**
- Open FileMaker Server Admin Console
- Go to **Configuration** → **Database Server**
- Check the **Maximum Concurrent Sessions** setting
- Default is usually 50-250 depending on your FileMaker Server license
- Increase this limit if needed (requires server restart)

### 2. Account Privilege Set Connection Limits

**Check Account Privileges:**
1. Open your FileMaker database file
2. Go to **File** → **Manage** → **Security**
3. Select the account: **login**
4. Check the **Privilege Set** assigned to this account
5. Click **Edit** on the Privilege Set
6. Look for **"Connection Limits"** or **"Maximum Connections"** setting
7. **Remove or increase the connection limit** if one is set

**Common Issue:** If the privilege set has a connection limit of 1 or a low number, only that many sessions can be active at once for that account.

### 3. FileMaker Data API Settings

**Enable Data API:**
1. FileMaker Server Admin Console
2. Go to **Configuration** → **Database Server**
3. Ensure **"Enable Data API"** is checked
4. Apply changes and restart if necessary

### 4. Check Active Connections

**Monitor Current Usage:**
1. FileMaker Server Admin Console
2. Go to **Activity** → **Connections**
3. See how many active connections you have
4. Check if connections are being properly closed

### 5. Recommended Settings for API Access Account

**For the "login" account used for API access:**
- **Privilege Set:** Should have full access to the tables/layouts needed
- **Connection Limit:** Set to **"No Limit"** or a high number (e.g., 100)
- **Auto-logout:** Can be enabled to automatically close idle sessions
- **Data API Access:** Should be enabled in the privilege set

### 6. Best Practices

1. **Close sessions immediately after use** (the app now does this)
2. **Use a dedicated API account** with appropriate privileges
3. **Monitor connection usage** regularly
4. **Set reasonable auto-logout times** for idle sessions
5. **Consider using connection pooling** if you have many concurrent users

### 7. Quick Fix Checklist

- [ ] Check if "login" account privilege set has connection limits
- [ ] Remove or increase connection limits in privilege set
- [ ] Check FileMaker Server maximum concurrent sessions setting
- [ ] Verify Data API is enabled on the server
- [ ] Check current active connections in Admin Console
- [ ] Restart FileMaker Server if you changed settings
- [ ] Test with the updated app (sessions now close immediately)

### 8. Testing

After making changes:
1. Close all FileMaker client connections
2. Wait a few moments for sessions to clear
3. Test the login from the iOS app
4. Check connections in Admin Console to verify they're closing properly
