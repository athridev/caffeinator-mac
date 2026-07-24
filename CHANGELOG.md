# Caffeinator 1.1

## Design and UX

- Redesigned 356 × 500 status panel with clearer active/standby contrast.
- Added a live Awake Shield card and remaining-time presentation.
- Added 30-minute, 1-hour, 4-hour, and unlimited session controls.
- Improved hover, focus, haptic, timed-session, and preferred-session states.
- Refined active, inactive, and timed menu-bar icon states.
- Coffee splash toast now names the selected session.

## Controls

- Global Option-Command-C toggle using the native Carbon hotkey API.
- Option-click the menu-bar cup to inspect without toggling.
- Space or Return toggles from the popup.
- Number keys 1–4 start the matching session.
- Escape dismisses the popup.
- Right-click menu includes session selection and visible checkmarks.

## Efficiency and validation

- Fast drawing refresh runs only during the short visible animation window.
- Popup refresh falls back to once per second only when active, then stops when hidden.
- Timed sessions automatically terminate the macOS caffeine process.
- Tested start, stop, duration changes, timed expiry, hotkey registration, rendering,
  signing, universal architectures, archive integrity, and idle resource use.
