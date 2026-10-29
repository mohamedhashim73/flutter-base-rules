# Credexa Firebase authorization

Credexa keeps application data tenant-scoped. Existing users without organization claims use `users/{uid}`; provisioned team members use the shared `organizations/{organizationId}` scope. Firebase Auth custom claims provide the organization and authoritative authorization. The client may read claims to adapt the UI, but Firestore rules remain the security boundary.

Supported role claims:

- `role: manager`
- `role: accountant`
- `role: employee`
- `organizationId: <shared organization id>`

Optional boolean permission claims are stored under `permissions`, for example:

```json
{
  "role": "accountant",
  "permissions": {
    "settlements.review": true,
    "treasury.accounts.manage": false,
    "records.edit": true
  }
}
```

Claims must be provisioned by a trusted Firebase Admin environment or Cloud Function. They must not be written by the Flutter client. After changing claims, the user must refresh their ID token or sign in again.

The configurable treasury approval threshold is stored at `system_settings/finance` inside the active user or organization scope. Firestore rules allow that document to be changed only for the manager claim. The client defaults to EGP 5,000 (`500000` minor units) until the setting exists.
