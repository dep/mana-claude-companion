# mana: a claude companion

A Claude Code companion built for MacOS that floats on top of your windows and reacts to Claude Code and opencode activity via hooks.

![CleanShot 2026-03-07 at 06 16 34](https://github.com/user-attachments/assets/22e7d7d8-9c07-4602-95c2-a9e321041ec5)

## Download

Grab the latest notarized build from [Releases](https://github.com/dep/mana/releases), then set up your hooks as described below.

## Build & Run

**Requirements:** macOS 13.0+, Xcode, [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

```bash
xcodegen generate
xcodebuild -project Mana.xcodeproj -scheme Mana -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/Mana-*/Build/Products/Debug/Mana.app
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
          "command": "jq -r '.prompt // empty' > ~/.claude/companion-prompt; echo working > ~/.claude/companion-state"
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

`UserPromptSubmit` hooks receive the payload on stdin as JSON — the `jq` command extracts the prompt text and writes it to `~/.claude/companion-prompt` so Mana can react contextually to what you asked.

## opencode Hooks Setup

Symlink the included plugin into opencode's plugins directory so updates are picked up automatically:

```bash
mkdir -p ~/.config/opencode/plugins
ln -s /path/to/mana/companion-opencode-plugin.js ~/.config/opencode/plugins/mana.js
```

Or copy if you prefer a static install:

```bash
cp companion-opencode-plugin.js ~/.config/opencode/plugins/mana.js
```

The plugin maps opencode lifecycle events to the same state files:

| opencode event | companion state |
|---|---|
| `chat.message` | `working` |
| `tool.execute.before` | `working` |
| `permission.ask` | `needsInput` |
| `session.idle` | `success` |

## Sound Effects

Mana plays audio cues on state transitions. The sounds are bundled in the app — no additional setup required. Tapping Mana while she's spinning dismisses the spin and resyncs to the current agent state.
