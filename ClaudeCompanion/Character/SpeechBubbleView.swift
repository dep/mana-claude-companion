import SwiftUI

struct SpeechBubbleView: View {
    let message: String

    var body: some View {
        ZStack(alignment: .bottom) {
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.bottom, 6)

            // Tail pointing down
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 7)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

enum SpeechMessages {
    static let idleMorning = [
        "Good morning~! ☀️",
        "Rise and code!",
        "Morning! Ready to go?",
        "Fresh start today! ✨",
        "Coffee first? ☕",
    ]

    static let idleAfternoon = [
        "Afternoon grind~",
        "Ready when you are!",
        "What's next? ☆",
        "Still here for you!",
        "Hmm hmm hmm~",
    ]

    static let idleEvening = [
        "Evening session~! 🌙",
        "Almost done for today?",
        "Night owl mode ✨",
        "I'm here!",
        "One more feature? 👀",
    ]

    static let idleLateNight = [
        "Late night coding? 🌙",
        "Don't forget to sleep!",
        "You're still up? 👀",
        "Burning the midnight oil~",
        "I'll keep you company ★",
    ]

    static let working = [
        "On it!",
        "Working hard~",
        "Leave it to me!",
        "Ganbarimasu!",
        "Let me handle this!",
        "Full speed ahead!",
    ]

    static let success = [
        "Done! ★",
        "Ta-da~!",
        "All finished!",
        "Easy peasy!",
        "Nailed it! ♪",
        "Yatta~!",
    ]

    static let needsInput = [
        "Your turn!",
        "Whatcha think?",
        "Over to you~",
        "I'm listening ★",
        "Your move!",
    ]

    static func random(for state: CompanionState) -> String {
        switch state {
        case .idle:       return randomIdle()
        case .working:    return working.randomElement()!
        case .success:    return success.randomElement()!
        case .needsInput: return needsInput.randomElement()!
        case .spinning:   return "Wheee~! ★"
        }
    }

    private static func randomIdle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return idleMorning.randomElement()!
        case 12..<17: return idleAfternoon.randomElement()!
        case 17..<22: return idleEvening.randomElement()!
        default:      return idleLateNight.randomElement()!
        }
    }
}
