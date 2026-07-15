# Mute UI Colors & Fix Backup Settings TypeError

This plan addresses two issues: the overly bright "Interest Management" UI and a `TypeError` in the Backup settings where a string `"false"` is incorrectly treated as a boolean.

## User Review Required

- The sidebar in "Interest Management" will be changed from bright orange to a muted dark neutral color (`#1A1A1A`). This significantly changes the visual weight of the page.

## Proposed Changes

### [Backup Settings Bug Fix]

#### [backup_settings_viewmodel.dart](file:///C:/Users/Grace Anne/Desktop/LARAVEL/capstone-application/lib/viewmodels/backup_settings_viewmodel.dart)

- Update `_parseValue` to handle boolean strings even when the `type` is reported as `"string"` by the API.
- Ensure `notifySuccess` and `notifyFailure` getters handle potential type mismatches safely.

```diff
-  bool get notifySuccess => _settings['backup_notify_success'] ?? true;
+  bool get notifySuccess => _toBool(_settings['backup_notify_success']) ?? true;

+  bool? _toBool(dynamic value) {
+    if (value is bool) return value;
+    if (value is String) return value.toLowerCase() == 'true';
+    return null;
+  }
```

---

### [UI Enhancement: Interest Management]

#### [update_interest_page.dart](file:///C:/Users/Grace Anne/Desktop/LARAVEL/capstone-application/lib/views/update_interest_page.dart)

- Change sidebar background to a dark neutral color.
- Adjust text colors in the sidebar for better contrast against the new dark background.

```diff
-    final sidebarBg = Color.alphaBlend(theme.primaryColor.withValues(alpha: 0.9), Colors.black);
+    final sidebarBg = const Color(0xFF1E1E1E); // Muted dark neutral
```

## Verification Plan

### Automated Tests
- Run `analyze_file` on both modified files to ensure no syntax or type errors.

### Manual Verification
- **Bug Fix**: Verify the logcat (if possible) or check that the settings page no longer crashes when "backup_notify_success" is `"false"`.
- **UI**: Check the new "Interest Management" page layout and color contrast.
