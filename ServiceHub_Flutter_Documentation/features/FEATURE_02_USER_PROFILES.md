# Feature 02 — User Profiles

**Owner:** Member 2 | **Dependencies:** Feature 01

## Goal
Authenticated users can view and update their own profile.

## Scope
- Display full name, profile image, email, phone (if collected), role, and relevant details.
- Customer: basic personal/contact details.
- Provider: professional description and optional location/contact details.
- Supplier: business name, description, and contact details.
- Edit permitted fields and select/replace profile image if upload is supported.
- Validate fields and show loading, success, and error states.
- Provide logout entry point by reusing Feature 01 session service.

## Rules
- Users can only view/update their own profile in mobile.
- Role cannot be changed through profile editing.
- No admin profile-management screens.

## Screens
My Profile, Edit Profile, image selection/upload state, loading/error states.

## Acceptance criteria
Profile loads from backend; permitted changes persist; role cannot be self-escalated; no admin management UI.
