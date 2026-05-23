# School Attendance Monitoring System

Flutter + Firebase attendance monitoring for school gate entry and exit sessions:

- Morning Time In
- Morning Time Out
- Afternoon Time In
- Afternoon Time Out

The app supports three Firebase-authenticated roles:

- System Administrator
- School Administrator
- Staff Scanner

## Implemented Modules

- Secure Firebase email/password login with role validation from `users`
- Role-protected navigation with unauthorized access logout
- Audit logging for login, logout, creation, settings, export, backup, and attendance actions
- System Administrator pages: dashboard, user management, audit logs, settings, database management, archives
- School Administrator pages: dashboard, scanner users, school years, students, sections, teachers, attendance logs, attendance status, early students, reports, archives
- Staff Scanner pages: ID scanner and attendance logs
- Offline scanner queue using local device storage with automatic sync on reconnect
- Duplicate attendance prevention using `personId + date + attendanceType`
- Active school year enforcement before logging attendance
- Student and teacher attendance threshold handling
- Excel and PDF export services
- Firestore and Storage security rule starters

## Firebase Setup

1. Create a Firebase project.
2. Enable Firebase Authentication with Email/Password.
3. Enable Firestore and Storage.
4. Run:

```sh
flutterfire configure
```

5. Replace the placeholder values in `lib/core/services/firebase_options.dart` with the generated Firebase options.
6. Publish the provided rules:

```sh
firebase deploy --only firestore:rules,storage
```

## Required Firestore Collections

- `users`
- `school_years`
- `terms`
- `students`
- `teachers`
- `sections`
- `attendance_logs`
- `archives`
- `audit_logs`
- `backups`
- `scanner_devices`
- `exports`
- `system_settings`

## First User

Create the first System Administrator manually in Firebase Auth, then create a matching Firestore document:

```json
{
  "email": "admin@example.edu",
  "fullName": "System Administrator",
  "role": "system_administrator",
  "status": "active",
  "schoolId": "default"
}
```

Use the Firebase Auth UID as the document ID in `users`.
