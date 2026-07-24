# Contributing to Caffeinator

Thanks for helping make the small things feel better.

## Before you start

- Search existing issues before opening a new one.
- Keep proposals focused on the core job: making Mac awake-state obvious and easy to control.
- Prefer native macOS APIs and zero runtime dependencies.
- Avoid features that require accounts, telemetry, or background networking.

For meaningful product changes, open an issue first so the interaction and resource tradeoffs can be discussed before implementation.

## Local setup

Requirements:

- macOS 13 or later
- Apple Command Line Tools

```bash
git clone <your-fork-url>
cd caffeinator-mac
make test
```

Quit any running Caffeinator instance before testing the global hotkey.

## Pull requests

1. Fork the repository.
2. Create a focused branch: `git switch -c feature/short-description`.
3. Make the smallest coherent change.
4. Run `make test`.
5. Include before/after screenshots for visual changes.
6. Explain the user impact and resource impact in the pull request.

Please keep pull requests small enough to review in one sitting.

## Design principles

- **Glanceable:** state should be understood without reading instructions.
- **Delightful, not distracting:** animation should confirm an action and then disappear.
- **Reversible:** every awake assertion must have a clear release path.
- **Native:** use AppKit and macOS APIs before adding a dependency.
- **Quiet at idle:** no timers, polling, or networking unless the visible experience requires it.
- **Accessible:** preserve keyboard navigation, useful labels, and strong contrast.

## Code style

- Follow existing Swift naming and layout.
- Keep state transitions in `CaffeinationController`.
- Keep visual drawing in the dashboard or overlay types.
- Use weak captures for timer and UI callbacks.
- Release system resources explicitly on stop and termination.

## Reporting bugs

Use the bug report template and include:

- macOS version and Mac architecture
- Caffeinator version
- exact reproduction steps
- whether the menu-bar state and `pmset -g assertions` disagree
- screenshots when the issue is visual
