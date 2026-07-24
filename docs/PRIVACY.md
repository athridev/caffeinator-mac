# Privacy

Caffeinator is designed to have almost nothing to say in a privacy policy.

## Data collection

Caffeinator does not collect, transmit, sell, or share data.

It has:

- no analytics
- no telemetry
- no crash-reporting SDK
- no account system
- no advertising
- no network client
- no third-party runtime dependencies

## Local state

Caffeinator stores one local preference in macOS `UserDefaults`: the last selected session duration. It does not store usage history.

## System access

Caffeinator launches macOS's built-in `/usr/bin/caffeinate` with flags that prevent idle display sleep, system sleep, and disk sleep. The child process is terminated when the session ends or the app quits.

The popup briefly observes global mouse-down events only to dismiss itself when you click elsewhere. Those events are not recorded, inspected, or stored.

Caffeinator does not request Accessibility, Screen Recording, Files and Folders, microphone, camera, contacts, calendar, location, or notification permission.

## Network verification

The source contains no network framework or endpoint. You can audit the complete implementation in `Sources/`.
