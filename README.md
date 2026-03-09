# claude-companion

A macOS menu bar companion that reacts to Claude Code and opencode activity via hooks.

![CleanShot 2026-03-07 at 06 16 34](https://github.com/user-attachments/assets/22e7d7d8-9c07-4602-95c2-a9e321041ec5)

## Requirements

- macOS 13.0+
- Xcode
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & Run

```bash
xcodegen generate
xcodebuild -project ClaudeCompanion.xcodeproj -scheme ClaudeCompanion -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/ClaudeCompanion-*/Build/Products/Debug/ClaudeCompanion.app
```

## Claude Code Hooks Setup

Add the following to `~/.claude/settings.json` to wire up the companion state:

```json
"hooks": {
  "Notification": [
    {
      "matcher": "permission_prompt",
      "hooks": [
        {
          "type": "command",
          "command": "echo needsInput > ~/.claude/companion-state"
        }
      ]
    }
  ],
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "echo working > ~/.claude/companion-state"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "echo working > ~/.claude/companion-state"
        }
      ]
    }
  ],
  "Stop": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "echo success > ~/.claude/companion-state"
        }
      ]
    }
  ]
}
```

## opencode Hooks Setup

Copy or symlink the included plugin to opencode's plugins directory:

```bash
mkdir -p ~/.config/opencode/plugins
cp companion-opencode-plugin.js ~/.config/opencode/plugins/claude-companion.js
# or symlink to pick up updates automatically:
# ln -s /path/to/claude-companion/companion-opencode-plugin.js ~/.config/opencode/plugins/claude-companion.js
```

The plugin maps opencode lifecycle events to the same `~/.claude/companion-state` file:

| opencode event | companion state |
|---|---|
| `tui.prompt.append` | `working` |
| `tool.execute.before` | `working` |
| `permission.asked` | `needsInput` |
| `session.idle` | `success` |
