# Authentication, Shareholder, and Notification Improvements

This plan addresses authentication feedback, shareholder capital notifications, and storage URL issues.

## Proposed Changes

### Auth Component (Flutter)

#### [auth_viewmodel.dart](file:///C:/Users/Grace Anne/Desktop/LARAVEL/capstone-application/lib/viewmodels/auth_viewmodel.dart)

- Add a private helper method `_mapAuthError(Object e)` to translate technical exceptions into friendly messages.
- Update `verifyMfa`, `resendMfa`, `login`, and `resendVerificationEmail` to use this helper.

---

### Shareholder Component (Laravel Backend)

#### [ShareholderController.php](file:///C:/Users/Grace Anne/Desktop/LARAVEL/capstone-application/laravel_backend/app/Http/Controllers/Api/ShareholderController.php)

- Update `updateCapital` to create a notification when share capital is added.
- The notification will inform the shareholder about the new capital contribution.

```php
// In updateCapital method
Notification::create([
    'shareholder_id' => $shareholder->id,
    'user_id' => $shareholder->user_id,
    'title' => 'Share Capital Updated',
    'content' => 'Your total share capital has been updated to ₱' . number_format($request->total_share_capital, 2) . '.',
    'category' => 'transaction',
    'type' => 'capital_updated',
    'is_unread' => true,
]);
```

---

### UI Component (Flutter)

#### [shareholder_detail_page.dart](file:///C:/Users/Grace Anne/Desktop/LARAVEL/capstone-application/lib/views/shareholder_detail_page.dart)

- Add `errorBuilder` to `Image.network` for the ID Document.
- Display a friendly message (e.g., "Image failed to load. Please check if the storage bucket is public.") instead of the 400 error.

## Verification Plan

### Manual Verification
1.  **MFA**: Trigger an expired OTP and verify the message is friendly.
2.  **Notification**: Add share capital as an admin and check the shareholder's notification screen.
3.  **ID Image**: View an ID document with a broken URL and verify the error is handled gracefully.

