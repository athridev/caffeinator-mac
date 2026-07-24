# Caffeinator launch checklist

Use this checklist for the first public release.

## Repository

- Repository name: `caffeinator-mac`
- Visibility: Public
- Description: `A tiny native macOS menu-bar app that keeps your Mac awake for remote work—one click, timed sessions, zero tracking.`
- Website: the latest GitHub release URL
- Topics:
  - `macos`
  - `swift`
  - `appkit`
  - `menu-bar-app`
  - `caffeinate`
  - `productivity`
  - `remote-work`
  - `open-source`
- Social preview: `media/social-preview.png`

Before publishing:

```bash
make test
git diff --check
```

## Release

1. Push `main` and confirm the **Build** workflow passes.
2. Create and push the `v1.1` tag.
3. Confirm the **Release** workflow creates a public release containing
   `Caffeinator-macOS.zip`.
4. Download that archive once and verify it opens.
5. Check the README's **Download the latest release** link from a logged-out window.

## Launch posts

1. Attach `media/social-preview.png`.
2. Replace `[GITHUB_URL]` in the prepared social copy.
3. Post when you can stay available to answer early questions.
4. Reply conversationally and ask testers for their macOS version when they report
   a problem.
5. Add recurring feedback to GitHub Issues instead of letting it disappear in a
   social thread.

## First-week follow-up

- Pin the repository on the GitHub profile.
- Add the first real user quote to the README only with permission.
- Turn repeated installation questions into documentation.
- Label suitable first contributions with `good first issue`.
- Publish one short build note about the native AppKit architecture and resource use.
