# Firestore Admins Collection Structure

## Collection: `admins`

### Example Document 1 (Super Admin)
```json
Document ID: "abc123def456ghi789" (auto-generated)
{
  "username": "super_admin",
  "email": "superadmin@sporteve.com",
  "passwordHash": "a8b8f4f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10", 
  "role": "super_admin",
  "displayName": "Super Admin",
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "lastLoginAt": "2024-01-20T14:22:15Z",
  "createdBy": "system"
}
```

### Example Document 2 (Regular Admin)
```json
Document ID: "xyz789abc123def456" (auto-generated)
{
  "username": "john_doe", 
  "email": "john.doe@sporteve.com",
  "passwordHash": "b9c9f5f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11",
  "role": "admin",
  "displayName": "John Doe",
  "isActive": true,
  "createdAt": "2024-01-16T09:15:30Z",
  "lastLoginAt": "2024-01-21T16:45:22Z",
  "createdBy": "abc123def456ghi789"
}
```

### Example Document 3 (Content Manager)
```json
Document ID: "def456ghi789jkl012" (auto-generated)
{
  "username": "sarah_wilson",
  "email": "sarah.wilson@sporteve.com", 
  "passwordHash": "c1d1f6f1e2f12f1f1e2f12f1f1e2f12f1f1e2f12f1f1e2f12f1f1e2f12f1f1e2f12",
  "role": "admin",
  "displayName": "Sarah Wilson",
  "isActive": true,
  "createdAt": "2024-01-17T11:20:45Z",
  "lastLoginAt": "2024-01-21T13:10:18Z",
  "createdBy": "abc123def456ghi789"
}
```

### Example Document 4 (Deactivated Admin)
```json
Document ID: "ghi789jkl012mno345" (auto-generated)
{
  "username": "former_admin",
  "email": "former@sporteve.com",
  "passwordHash": "d2e2f7f2e3f13f2f2e3f13f2f2e3f13f2f2e3f13f2f2e3f13f2f2e3f13f2f2e3f13",
  "role": "admin", 
  "displayName": "Former Admin",
  "isActive": false,
  "createdAt": "2024-01-10T08:45:12Z",
  "lastLoginAt": "2024-01-18T17:30:45Z",
  "createdBy": "system",
  "updatedAt": "2024-01-19T09:15:22Z",
  "updatedBy": "abc123def456ghi789"
}
```

## Field Details

### `username` (string)
- Unique identifier for login
- Alphanumeric, dots, underscores allowed
- Examples: "john_doe", "admin", "sarah.wilson"

### `email` (string) 
- Valid email address for login
- Must be unique across all admin accounts
- Examples: "john@sporteve.com", "admin@sporteve.com"

### `passwordHash` (string)
- SHA-256 hash of the plain text password
- Never store plain text passwords
- Generated automatically by the app

### `role` (string)
- "admin": Can manage content (news, tournaments, athletes)
- "super_admin": Can manage content + admin accounts

### `displayName` (string)
- Full name shown in the UI
- Used as author name in news articles
- Examples: "John Doe", "Sarah Wilson"

### `isActive` (boolean)
- true: Account is active and can login
- false: Account is deactivated, cannot login

### `createdAt` (timestamp)
- When the admin account was created
- Automatically set by Firestore

### `lastLoginAt` (timestamp, optional)
- Last time this admin logged in
- Updated automatically on successful login

### `createdBy` (string, optional)
- Document ID of the admin who created this account
- "system" for initial setup accounts

### `updatedAt` (timestamp, optional)
- Last time this account was modified
- Set when admin details are updated

### `updatedBy` (string, optional)
- Document ID of admin who made the last update

## Security Rules (Recommended)

```javascript
// Firestore Security Rules for admins collection
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated admin users can access admin collection
    match /admins/{adminId} {
      allow read, write: if request.auth != null && 
                           exists(/databases/$(database)/documents/admins/$(request.auth.uid)) &&
                           get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isActive == true;
    }
  }
}
```

## Initial Setup

The app automatically creates these initial accounts:

1. **Super Admin Account**
   - Username: `super_admin`
   - Password: `sporteve_super_2024` 
   - Role: `super_admin`

2. **Regular Admin Account**  
   - Username: `admin`
   - Password: `sporteve2024`
   - Role: `admin`

## Password Examples

Here are some example password hashes (SHA-256):

- Password: "sporteve2024" → Hash: "a8b8f4f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10e8f8e9f10"
- Password: "mysecurepass123" → Hash: "b9c9f5f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11e9f9e0f11"

*Note: These are example hashes for illustration. Actual hashes will be different.*
