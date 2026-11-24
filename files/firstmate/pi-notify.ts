import { existsSync, realpathSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// This is deliberately loaded with -e only in the primary Pi, not installed in
// Pi's global extensions directory. Neither the response nor the prompt is sent
// to Windows: the notification carries a fixed, non-sensitive message.
const script = `
$ErrorActionPreference = 'Stop'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] > $null
$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$text = $xml.GetElementsByTagName('text')
$text.Item(0).AppendChild($xml.CreateTextNode('Firstmate')) > $null
$text.Item(1).AppendChild($xml.CreateTextNode('The primary session needs your attention.')) > $null
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Microsoft.Windows.PowerShell').Show($toast)
`;

export default function (pi: ExtensionAPI) {
  let enabled = false;
  let candidate: string | undefined;
  let lastNotified: string | undefined;
  let promptOpen = false;

  function notify() {
    // A missing Windows interop executable or a failed notification must never
    // break the agent. Bound the child and do not hold Pi's lifecycle open.
    void pi.exec("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command", script], { timeout: 5000 }).catch(() => {});
  }

  pi.on("session_start", (_event, ctx) => {
    enabled = false;
    candidate = undefined;
    lastNotified = undefined;
    promptOpen = false;
    if (ctx.mode !== "tui" || !process.env.WSL_DISTRO_NAME || !process.env.FM_HOME) return;
    try {
      const home = realpathSync(process.env.FM_HOME);
      enabled = realpathSync(ctx.cwd) === home &&
        existsSync(join(home, "bin/fm-session-start.sh")) &&
        !existsSync(join(home, ".fm-secondmate-home"));
    } catch {
      // Fail closed when primary identity cannot be established.
    }
  });

  pi.on("turn_end", (event) => {
    candidate = undefined;
    if (!enabled || event.message.role !== "assistant" || event.message.stopReason !== "stop") return;
    const text = event.message.content.filter((part) => part.type === "text").map((part) => part.text).join("\n").trim();
    if (!text || text === "MONITOR_NOTIFICATION_HANDLED") return;
    candidate = event.messageEntryId;
  });

  pi.on("agent_settled", (event) => {
    if (event.aborted) {
      candidate = undefined;
      return;
    }
    if (!enabled || !candidate || candidate === lastNotified) return;
    lastNotified = candidate;
    candidate = undefined;
    notify();
  });

  pi.on("ui_prompt_start", () => {
    if (!enabled || promptOpen) return;
    promptOpen = true;
    notify();
  });
  pi.on("ui_prompt_end", () => { promptOpen = false; });
}
