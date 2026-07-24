# Security policy

## Supported version

Security fixes are applied to the latest release.

## Reporting a vulnerability

Please do not open a public issue for a vulnerability that could affect users.

Use the repository's **Security → Report a vulnerability** flow to open a private security advisory. Include:

- the affected version
- reproduction steps
- expected impact
- any suggested mitigation

You should receive an initial response within seven days.

## Security model

Caffeinator:

- runs entirely on the local Mac
- makes no network requests
- stores no credentials or personal information
- launches only macOS's built-in `/usr/bin/caffeinate`
- does not request Accessibility, Screen Recording, microphone, camera, or location access

The distributed app is currently ad-hoc signed rather than Developer ID notarized. Only download releases from this repository, and verify the archive or build from source when stronger provenance is required.
