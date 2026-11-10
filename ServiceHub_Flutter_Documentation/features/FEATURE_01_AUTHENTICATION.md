# Feature 01 — Authentication & Role-Based Access

**Owner:** Member 1 | **Dependencies:** Shared project setup

## Goal
Implement registration, login, session restoration, logout, and mobile role restrictions.

## Registration
- Register with full name, email, password, confirmation, and role.
- Mobile roles: CUSTOMER, PROVIDER, SUPPLIER only.
- Validate required fields, email, password rules, and matching confirmation.
- Display backend validation errors and prevent duplicate submissions.

## Login and session
- Email/password login; show/hide password.
- Display invalid-credential/server errors.
- Store JWT securely and retrieve current user/role.
- Restore valid session on app launch.
- Attach token centrally to authenticated requests.
- Handle expired/invalid tokens.
- Logout and clear stored credentials.
- Never log passwords or tokens.

## Admin restriction
- Never allow public registration as ADMIN.
- ADMIN is not a mobile role.
- If ADMIN signs in, block mobile feature access and show: “Administration will be available through the web backoffice.”
- Do not build admin dashboard or reports UI.

## Screens
Login, registration, session loading, and admin/mobile-access-blocked state.

## Acceptance criteria
Registration/login work; validation is clear; token persists securely; logout clears session; role is available to navigation; ADMIN cannot use mobile functionality. Use setState only.
