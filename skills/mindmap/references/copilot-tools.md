# Copilot setup notes

The skill describes capabilities, not fixed tool names. In GitHub Copilot, use
the tools exposed by the current session; names and availability vary by version
and host. These are examples, not a required mapping or a permission grant.

| Capability | Example tool names |
|---|---|
| Read a file | `view` |
| Create or edit a file | `create`, `edit`, `apply_patch` |
| Inspect paths or find files | `glob`, filesystem queries through a command tool |
| Retrieve a URL | `web_fetch` |
| Execute commands | `bash`, `powershell` |

## Optional features

- **`--render`:** the supplied `render.sh` requires a Bash executable and
  Node.js / `npx`, regardless of the command tool's name. If unavailable, keep the
  Markdown and report why HTML was not generated, with a manual rendering command.
- **`--panel`:** requires independent subagent delegation and result collection.
  Use the host's available tools and the protocol in `judge-panel.md`; no
  particular workflow API is assumed. If unavailable, ask before continuing
  without the panel.
- **Permissions:** follow the host's file-access, network, command-execution,
  and subagent approval rules. Installation does not enable these capabilities.
