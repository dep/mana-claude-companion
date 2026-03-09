// ClaudeCompanion plugin for opencode
// Install: copy or symlink to ~/.config/opencode/plugins/claude-companion.js

export const ClaudeCompanionPlugin = async ({ $ }) => {
  const setState = (state) => $`echo ${state} > ~/.claude/companion-state`

  return {
    "tui.prompt.append": async () => {
      await setState("working")
    },
    "tool.execute.before": async () => {
      await setState("working")
    },
    "permission.asked": async () => {
      await setState("needsInput")
    },
    "session.idle": async () => {
      await setState("success")
    },
  }
}
