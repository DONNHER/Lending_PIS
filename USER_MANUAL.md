# User & Administrator Manual - Capstone Application

## 🌟 Introduction
Welcome to the Capstone Application. This manual provides instructions for administrators and staff on how to manage the system, including security, backups, and data management.

---

## 🔐 Security & Access
### Multi-Factor Authentication (MFA)
1. **Login**: Enter your email and password.
2. **OTP**: Check your registered email for a 6-digit verification code.
3. **Verify**: Enter the code into the app to complete login.
*Note: OTPs expire after 10 minutes.*

### Account Lockout
Accounts are automatically locked for **15 minutes** after 5 failed login attempts to prevent unauthorized access.

---

## 🛠️ Administrative Features
### User Management
Located under **Admin > Users**.
- **Create/Edit**: Add new staff or members. Ensure roles are assigned correctly.
- **Impersonate**: Admins can log in as any user to provide direct support.
- **Force Logout**: Use this if a user's device is lost or stolen to instantly terminate their session.

### Automated Backups
Located under **Admin > Backups**.
- **Database**: Scheduled weekly (Sunday 2:00 AM).
- **Files**: Scheduled weekly (Sunday 3:00 AM).
- **Retention**: The system automatically deletes backups older than 30 days.
- **Manual**: Click "Run Backup" at any time for an immediate snapshot.

---

## 📊 Dashboard & Reports
The Dashboard provides real-time health and performance metrics:
- **Registration Trends**: Track growth over weeks or months.
- **Active Sessions**: See current system load.
- **Audit Trail**: Every sensitive action (Deletes, Updates, Status changes) is logged with the user's name and IP address.

---

## 📁 Data Management
### Advanced Controls
Most data tables (Shareholders, Products, Loans) support:
- **Bulk Actions**: Select multiple rows to delete or export at once.
- **Optimistic Locking**: If you see a "Conflict Detected" error, it means another user updated the same record while you were editing it. Please refresh your view.
- **Soft Delete**: Deleting a record moves it to the "Trash". Admins can restore these records within 30 days.

---

## 📝 Support
For technical issues, please consult the **Activity Logs** to view specific error messages and stack traces.
