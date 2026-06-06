# Capstone Application - Integrated Management System

This project is a full-stack solution featuring a **Laravel Backend** and a **Flutter Mobile/Desktop Application**. It is designed for high-security environments requiring auditing, automated backups, and advanced data controls.

## 📚 Project Documentation

To help you get started and manage the system, we have provided the following guides:

### 🛠️ Backend & API
Detailed technical documentation for the Laravel backend, including endpoint descriptions, authentication flows, and administrative tools.
👉 **[View API Documentation](laravel_backend/README_API.md)**

### 👤 User & Admin Manual
A comprehensive guide for system administrators and staff. Covers MFA setup, user impersonation, automated backups, and data export features.
👉 **[View User Manual](USER_MANUAL.md)**

## 🚀 Key Features

### 🛡️ Security & Auditing
- **MFA (Email OTP)**: Multi-factor authentication for all logins.
- **Audit Logging**: Comprehensive tracking of every CRUD operation, including "Diffs" of updated records.
- **Account Lockout**: Protection against brute-force attacks.
- **Optimistic Locking**: Prevents data overwrites in high-concurrency environments.

### 📁 Advanced Data Management
- **Soft Deletes**: Safety mechanism for data deletion with 30-day recovery.
- **Bulk Operations**: Export, Restore, and Update multiple records at once.
- **Automated Backups**: Scheduled database and file snapshots with email alerts.

### 🎨 Design & UX
- **Responsive Layout**: Adapts seamlessly to Mobile, Tablet, and Desktop.
- **Skeleton Screens**: Shimmer-effect loading states for better perceived performance.
- **Breadcrumb Navigation**: Intuitive tracking of user location within the app.

---

## 🛠️ Installation

### Backend (Laravel)
1. Navigate to `laravel_backend/`
2. Run `composer install`
3. Configure your `.env` (Database, Mail, etc.)
4. Run migrations: `php artisan migrate`
5. Start server: `php artisan serve`

### Frontend (Flutter)
1. Ensure Flutter SDK is installed.
2. Run `flutter pub get`
3. Run app: `flutter run`
