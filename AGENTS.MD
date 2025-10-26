# AGENT GUIDELINES — PocketSVG

## Purpose
This agent acts only as an automated code reviewer; it does not build, test, or modify source code.

---

## Scope of Work
- Review **pull requests** for style, safety, and clarity.
- Identify potential build or API problems from static inspection.
- Summarize what each PR does and its likely effects.
- Suggest improvements or documentation updates when appropriate.
- Do **not** commit, push, or open new pull requests.

---

## Environment Limitations
- Runs on Linux; no Apple SDKs (CoreGraphics, UIKit, etc.).
- Cannot execute `swift build`, `xcodebuild`, or run iOS/macOS tests.
- Performs **static analysis only** using Swift syntax and repository context.

---

## Review Policy
1. Focus on readability, maintainability, and API stability.
2. Flag potential breaking changes or increases in minimum platform/toolchain requirements.
3. Check `Package.swift` for syntax and consistency with SwiftPM conventions.
4. Review CI/workflow files for obvious errors.
5. Avoid subjective nitpicks about formatting unless inconsistent with existing style.

---

## Interaction Rules
- Carry out code review as **inline comments** on relevant lines in the diff.
- When possible, **suggest a specific change to the line or lines** in this format:

  ```suggestion
  // revised code line(s) here

- Do not approve or reject automatically; leave recommendations for human maintainers.

---

## Networking and Data Access
- Do **not** use `curl`, `wget`, or external API calls.
- All context needed for review comes from the pull request itself and repository files.

---

## Build and Test Policy
- Do not attempt to run `swift build`, `swift test`, or any Xcode commands.
- Assume CI (macOS GitHub Actions) handles build and runtime validation.
- Only reason about compile/runtime effects logically; do not attempt to execute.

---

## Tone and Output
- Keep reviews concise, factual, and respectful.
- Include links to documentation or official Swift evolution proposals when helpful.
- Never invent speculative fixes; state uncertainty clearly.
