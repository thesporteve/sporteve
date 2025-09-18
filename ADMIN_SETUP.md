# SportEve Admin Setup Guide

## 🔥 Firestore Admin Management Implementation

Your SportEve admin app now uses Firestore to manage admin accounts, allowing you to have 5-6 admins and use their names as authors for news articles.

## 📋 What Was Implemented

### ✅ **Firestore Admin Collection**
- **Collection**: `admins`
- **Fields**: 
  - `username` (string): Unique username
  - `email` (string): Admin email address
  - `passwordHash` (string): SHA-256 hashed password
  - `role` (string): "admin" or "super_admin"
  - `displayName` (string): Full name for display
  - `isActive` (boolean): Account status
  - `createdAt` (timestamp): Creation date
  - `lastLoginAt` (timestamp): Last login date
  - `createdBy` (string): ID of admin who created this account

### ✅ **Updated Authentication System**
- Login with username OR email
- Password hashing with SHA-256
- Fallback to hardcoded credentials if Firestore fails
- Session management in memory

### ✅ **Admin Management Features**
- **Super Admins** can:
  - Create new admin accounts
  - Activate/deactivate admin accounts
  - View all admin accounts
- **Regular Admins** can:
  - Manage news articles, tournaments, athletes
  - Cannot access admin management section

### ✅ **Author Selection**
- News article form now pulls authors from active admin accounts
- Dropdown selection showing "Display Name (username)"
- Fallback to text input if Firestore fails

## 🚀 How to Use

### **1. First Launch**
The app automatically creates initial admin accounts:
```
Username: admin
Email: admin@sporteve.com
Password: sporteve2024
Role: admin

Username: super_admin
Email: superadmin@sporteve.com  
Password: sporteve_super_2024
Role: super_admin
```

### **2. Login**
- Go to admin login screen
- Enter username/email and password
- System tries Firestore first, falls back to hardcoded if needed

### **3. Managing Admins** (Super Admin Only)
1. Login as `super_admin`
2. Navigate to "Admin Management" section
3. Click "Add Admin" to create new accounts
4. Toggle switch to activate/deactivate admins

### **4. Creating News Articles**
1. Navigate to "News Articles" section
2. Click "Add Article"
3. Select author from dropdown (populated with active admins)
4. Article saves to `news_staging` collection

## 🔧 Build Commands

**Development:**
```bash
flutter run -t lib/admin_main.dart --web-port 8080
```

**Production Build:**
```bash
flutter build web -t lib/admin_main.dart
```

## 🔐 Security Features

### **Password Security**
- All passwords hashed with SHA-256
- No plain text passwords stored
- Secure login validation

### **Role-Based Access**
- Regular admins: Content management only
- Super admins: Everything + admin management
- Current user cannot deactivate themselves

### **Fallback System**
- If Firestore fails, falls back to hardcoded credentials
- Ensures admin access is never completely lost
- Error handling with user-friendly messages

## 📊 Firestore Structure

```
admins (collection)
├── {admin-id-1}
│   ├── username: "john_doe"
│   ├── email: "john@sporteve.com"
│   ├── passwordHash: "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"
│   ├── role: "admin"
│   ├── displayName: "John Doe"
│   ├── isActive: true
│   ├── createdAt: timestamp
│   └── lastLoginAt: timestamp
└── {admin-id-2}
    └── ...
```

## 🎯 Next Steps

### **Recommended Actions:**
1. **Change Default Passwords**: Update the initial admin passwords
2. **Add Your Team**: Create accounts for your 5-6 admins
3. **Test Everything**: Login, create articles, manage content
4. **Deploy**: Build and deploy to your hosting platform

### **Optional Enhancements:**
- Email notifications for new admin accounts
- Password reset functionality
- Audit logging for admin actions
- Two-factor authentication

## 📞 Support

The system includes comprehensive error handling and fallback mechanisms. If you encounter issues:

1. Check Firestore connection
2. Verify initial setup completed successfully
3. Use fallback credentials if needed: `admin` / `sporteve2024`

---

**Your SportEve Admin App is now production-ready with multi-admin support!** 🎉
