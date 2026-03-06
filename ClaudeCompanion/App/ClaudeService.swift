import Foundation

class ClaudeService {
    static let shared = ClaudeService()

    private let apiKey: String = {
        // GUI apps don't inherit shell env — read directly from ~/.zshrc
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty {
            return key
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", "source ~/.zshrc 2>/dev/null && echo $ANTHROPIC_API_KEY"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }()
    private let model = "claude-haiku-4-5-20251001"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func fetchQuip(for state: CompanionState, userPrompt: String? = nil) async -> String? {
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else { return nil }

        let prompt = systemPrompt(for: state, userPrompt: userPrompt)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 40,
            "messages": [["role": "user", "content": "Give me one quip."]]  ,
            "system": prompt
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String else { return nil }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func systemPrompt(for state: CompanionState, userPrompt: String? = nil) -> String {
        let persona = """
        You are Mana, a cute anime-style AI companion desktop buddy for a software developer. \
        You speak in short, punchy, funny one-liners — max 8 words. No quotes, no punctuation at the end unless it's ! or ~. \
        Occasionally use Japanese words like "Yatta", "Ganbare", "Nani", "Sugoi". \
        Be playful, a little sassy, and very charming.
        """
        switch state {
        case .idle:
            return persona + " The developer is idle. Say something chill, spacey, or gently bored."
        case .working:
            if let userPrompt {
                return persona + " The developer just asked Claude to: \"\(userPrompt)\". React to what they're working on — be contextual, energetic, and fun!"
            }
            return persona + " You're helping a developer who just sent a request. Say something energetic and ready-to-go."
        case .needsInput:
            return persona + " You're waiting for the developer to make a decision or give input. Say something expectant or a little impatient."
        case .success:
            return persona + " You just finished a task successfully. Say something triumphant or celebratory."
        case .spinning:
            return persona + " You're spinning around for fun. Say something dizzy or wheee-like."
        }
    }
}
