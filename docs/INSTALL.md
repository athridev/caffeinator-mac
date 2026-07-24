# Installation

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac

## Install a release

1. Open the repository's **Releases** page.
2. Download `Caffeinator-macOS.zip` from the latest release.
3. Unzip the archive.
4. Move `Caffeinator.app` to `/Applications`.
5. Open the app.

Caffeinator is a menu-bar utility, so it does not appear in the Dock.

## First-launch Gatekeeper message

The current public build is ad-hoc signed and is not Apple-notarized. If macOS blocks the first launch:

1. Control-click `Caffeinator.app`.
2. Choose **Open**.
3. Confirm **Open** once.

After that, the app opens normally.

Only use release files downloaded from this repository. If you prefer not to open an ad-hoc signed binary, build from source.

## Build from source

Install Apple's Command Line Tools:

```bash
xcode-select --install
```

Then:

```bash
git clone <your-fork-url>
cd caffeinator-mac
make build
open dist/Caffeinator.app
```

The output includes:

- `dist/Caffeinator.app`
- `dist/Caffeinator-macOS.zip`

## Confirm Caffeinator is working

Activate Caffeinator and run:

```bash
pmset -g assertions
```

The output should show `caffeinate` owning idle display, system, and disk assertions.

## Uninstall

1. Right-click the menu-bar cup and choose **Quit Caffeinator**.
2. Move `Caffeinator.app` to Trash.

Caffeinator installs no daemon, kernel extension, browser extension, or hidden support service.

## Troubleshooting

### The global shortcut does not respond

- Check whether another app already owns <kbd>⌥</kbd><kbd>⌘</kbd><kbd>C</kbd>.
- Quit and reopen Caffeinator.
- Use the menu-bar cup or right-click menu as a fallback.

### The cup is not visible

- Check the hidden menu-bar-items area if you use a menu-bar manager.
- Quit duplicate Caffeinator processes and reopen the copy in Applications.

### The Mac still sleeps

- Confirm the dashboard says **Remote Ready**.
- Check `pmset -g assertions`.
- Confirm Caffeinator has not reached the end of a timed session.
- File a bug with the macOS version and assertion output.
