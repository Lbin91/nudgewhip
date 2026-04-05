import SwiftUI

struct AnimatedASCIICharacterView: View {
    var hatchStage: PetHatchStage
    var character: PetCharacterType?
    var emotion: PetEmotion = .happy
    var frameInterval: TimeInterval = 1.0
    var animate = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var frames: [String] {
        ASCIIArtFrames.frames(for: hatchStage, character: character, emotion: emotion)
    }

    var body: some View {
        Group {
            if reduceMotion || !animate {
                frameText(frames.first ?? "")
            } else {
                TimelineView(.periodic(from: .now, by: frameInterval)) { timeline in
                    let index = Int(timeline.date.timeIntervalSince1970 / frameInterval) % max(frames.count, 1)
                    frameText(frames[index])
                }
            }
        }
    }

    private func frameText(_ ascii: String) -> some View {
        Text(ascii)
            .font(.monospaced(.body)())
            .foregroundStyle(Color.nudgeTextPrimary)
            .lineSpacing(2)
            .accessibilityLabel("Pet character animation")
    }
}
