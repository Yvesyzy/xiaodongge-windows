# Code signing policy

## Current status

The project is preparing an application for free open source signing from [SignPath Foundation](https://signpath.org/apply). No application approval, signing subscription or project certificate has been confirmed. The current v3.1.1 installer and portable release are **unsigned by this project**.

Only after approval and publication of a verified signed build will the following attribution apply: Free code signing provided by [SignPath.io](https://about.signpath.io/), certificate by [SignPath Foundation](https://signpath.org/).

## Project responsibilities

- Author, maintainer and reviewer: [Yvesyzy](https://github.com/Yvesyzy).
- Release and signing approver: [Yvesyzy](https://github.com/Yvesyzy).
- Changes from other contributors require maintainer review before signing.
- Each production signing request requires manual approval. Multi-factor authentication for GitHub and SignPath is required before production signing is activated; its activation has not been independently verified.

## Build and signing boundaries

The [Windows build workflow](../.github/workflows/codex_windows_build.yml) runs only on manual dispatch on a GitHub-hosted Windows runner. It uses the committed lockfile, checks types and unit tests, builds the portable package and installer, verifies the package inventory, and uploads explicitly selected unsigned artifacts. It does not sign files or publish Releases.

SignPath service identifiers, signing policy and credentials will be configured from the actual approved account. API tokens belong in GitHub Actions secrets. Passwords, private keys, local recovery records and personal application contacts must never enter this repository or build artifacts.

The requested signing scope is the project's installer and generated uninstaller. Electron and other upstream executable files keep their upstream identity and signatures. They must not be signed with a SignPath Foundation project certificate. The existing local certificate build mode is separate from the proposed SignPath workflow and is not a SignPath integration.

Before a signed release, verify the signer's certificate chain, publisher and timestamp, recompute SHA-256 checksums, and rerun isolated installation, upgrade and removal checks. A signature does not guarantee that Windows reputation checks will never display a warning.

## Privacy and review prerequisites

See the [Privacy policy](codex_privacy_policy.md) for local storage, automatic catalog queries in recording screens and optional weather queries. The application must disclose these behaviors to SignPath; it must not claim to have no network transfers.

The Foundation's [conditions](https://signpath.org/terms) also require installation-time privacy disclosure and an option to disable applicable data transfers. Those installation options are not implemented in v3.1.1. They require resolution with the Foundation before production signing. Project reputation, MFA and the Foundation's acceptance remain subject to review.

This policy describes the intended controls and current gaps; it does not claim that a certificate has been obtained or that the project has passed the Foundation's review.
