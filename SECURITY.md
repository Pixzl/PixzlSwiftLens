# Security Policy

## Supported versions

PixzlSwiftLens is in early development. Only the latest minor release receives security fixes.

| Version | Supported |
|---------|-----------|
| 0.2.x   | ✅        |
| < 0.2   | ❌        |

## Reporting a vulnerability

**Please do not open a public issue for security reports.**

Use GitHub's private vulnerability reporting:
**https://github.com/Pixzl/PixzlSwiftLens/security/advisories/new**

What to include:
- Affected version(s)
- A clear description of the issue and its impact
- A minimal reproduction (Swift snippet, sample request, etc.)
- Optional: a suggested fix or mitigation

You can expect:
- Acknowledgement within **3 business days**
- A status update within **7 business days**
- A fix or a public response within **30 days** for critical issues

## Scope

PixzlSwiftLens is a **debug-only** library and is compiled out of release builds. Reports are most relevant when they involve:

- Code paths that **leak into release builds** despite the `#if DEBUG` guard
- The URLProtocol swizzling causing **incorrect behavior** in production-shaped sessions
- The OSLog reader exposing logs **outside the current process scope**

Out of scope:
- Anything observable only with `--debug`-equivalent flags or in DEBUG configurations (that's the whole point of the tool)
