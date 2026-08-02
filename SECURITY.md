# Security Policy

CLonUI is a local-first desktop application that manages provider/API keys, MCP server
configuration, and local agent data. We take security seriously and appreciate
responsible disclosure.

## Reporting a vulnerability

**Please do not open a public issue for security vulnerabilities.**

Report a suspected vulnerability privately by emailing the repository maintainers, or use
GitHub's private vulnerability reporting (if enabled for this repository). When reporting,
include:

- A description of the vulnerability and its impact.
- The affected version(s) and platform(s) (macOS / Windows / Linux).
- Steps to reproduce, or a minimal proof of concept.
- Any suggested fix, if you have one.

You should receive an acknowledgement within **5 business days**. We ask that you keep
details confidential until a fix is released.

## What to report

Anything that could compromise a user's data or machine, for example:

- Local database (`CLONUI_DATA`) tampering or unauthorized access.
- Exposure of provider/API keys, MCP tokens, or secrets.
- Unsafe handling of MCP server connections or remote agent output (e.g. prompt injection
  that leads to arbitrary command execution).
- Unsafe IPC across the main/renderer process boundary.
- Installer or code-signing issues.

## Supported versions

| Version | Supported |
|---------|-----------|
| Latest release | ✅ |
| Older releases | ❌ — upgrade to the latest |

We only provide security fixes for the latest released version. Keep CLonUI up to date.

## Disclosure timeline

We aim to: acknowledge within 5 business days, and release a fix coordinated with the
reporter before public disclosure. We will credit reporters unless they prefer to remain
anonymous.

## Scope

This policy applies to this repository and its released artifacts. Third-party
dependencies and upstream components are subject to their own policies; please report
vulnerabilities in those to their respective maintainers.
