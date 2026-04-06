// ASCIIArtFrames.swift
// 캐릭터 ASCII 아트 프레임 컬렉션.
//
// PetHatchStage(.egg/.cracking/.hatched)와 PetCharacterType별
// 애니메이션 프레임을 제공한다. hatched 상태에서는 캐릭터별
// PetEmotion에 따른 프레임을 반환한다.
//
// 모든 ASCII 아트는 \n 조인 방식으로 작성하여
// multiline string literal 들여쓰기 문제를 방지한다.

import Foundation

enum ASCIIArtFrames {

    // MARK: - Public API

    /// 현재 상태에 맞는 애니메이션 프레임 배열을 반환.
    /// - Parameters:
    ///   - hatchStage: 알 부화 단계
    ///   - character: 캐릭터 타입 (egg/cracking에서는 무시됨)
    ///   - emotion: 캐릭터 감정 (egg/cracking에서는 무시됨)
    /// - Returns: 1초 간격으로 교체할 프레임 문자열 배열
    static func frames(
        for hatchStage: PetHatchStage,
        character: PetCharacterType? = nil,
        emotion: PetEmotion = .happy
    ) -> [String] {
        switch hatchStage {
        case .egg:
            return eggFrames()
        case .cracking:
            return crackingFrames()
        case .hatched:
            return hatchedFrames(
                character: character ?? .partyMask,
                emotion: emotion
            )
        }
    }

    // MARK: - Egg (알 상태 — 점점 금이 감)

    private static func eggFrames() -> [String] {
        return [
            "    ___\n   /   \\\n  | ~ ~ |\n   \\___/",
            "    ___\n   / _ \\\n  | ~ ~ |\n   \\___/",
            "    ___\n   / _ \\\n  | - - |\n   \\___/"
        ]
    }

    // MARK: - Cracking (부화 직전 — 금이 더 벌어짐)

    private static func crackingFrames() -> [String] {
        return [
            "    ___\n   / ╱  \\\n  | ◠ ◠ |\n   \\╱___/",
            "   _╱╲__\n  ╱ ╱  \\\n  | ◉ ◉ |\n  ╲╱╲__╱",
            "  _╱ ╲__\n ╱ ╱╱  \\\n | ✧ ✧ |\n ╲╱╲╱__╱"
        ]
    }

    // MARK: - Hatched (부화 완료 — 캐릭터별 감정 프레임)

    private static func hatchedFrames(
        character: PetCharacterType,
        emotion: PetEmotion
    ) -> [String] {
        switch character {
        case .partyMask:
            return ringmasterFrames(emotion: emotion)
        case .catwoman:
            return catwomanFrames(emotion: emotion)
        case .rat:
            return ratFrames(emotion: emotion)
        case .ox:
            return oxFrames(emotion: emotion)
        case .tiger:
            return tigerFrames(emotion: emotion)
        case .rabbit:
            return rabbitFrames(emotion: emotion)
        }
    }

    // MARK: Ringmaster (서커스 단장)

    // MARK: Catwoman (캣우먼)

    private static func catwomanFrames(emotion: PetEmotion) -> [String] {
        switch emotion {
        case .happy:
            return [
                "  /\\     /\\  \n |  ^   ^  | \n | ( ◕   ◕ ) | \n  \\    ◡    /  \n   \\_______/   ",
                "  /\\     /\\  \n |  ◕   ◕  | \n | (  > <  ) | \n  \\    ▽    /  \n   \\_______/   ",
                "  /\\     /\\  \n |  ◠   ◠  | \n | (  u u  ) | \n  \\    ‿    /  \n   \\_______/   "
            ]
        case .cheer:
            return [
                "  /\\     /\\   ✧\n |  ✪   ✪  | \n | (  O O  ) | \n  \\    ᗜ    /  ☆\n   \\_______/   ",
                "  /\\     /\\   ★\n |  >   <  | \n | (  * *  ) | \n  \\    ∀    /  ✧\n   \\_______/   ",
                "  /\\     /\\   ♪\n |  ^   ^  | !\n | (  O O  ) | ★\n  \\    O    /  \n   \\_______/   "
            ]
        case .sleep:
            return [
                "  /\\     /\\  \n |  -   -  | \n | (  u u  ) | \n  \\    ︶    /  \n   \\_______/   zZ",
                "  /\\     /\\  \n |  ~   ~  | \n | (  - -  ) | \n  \\    -    /  Zz",
                "  /\\     /\\  \n |  ◡   ◡  | \n | (  - -  ) | \n  \\    -    /  zZ"
            ]
        case .concern:
            return [
                "  /\\     /\\  \n |  •   •  | \n | (  • •  ) | \n  \\    ㅁ    /  \n   \\_______/   ??",
                "  /\\     /\\  \n |  °   °  | \n | (  _ _  ) | \n  \\    -    /  ...",
                "  /\\     /\\  \n |  •   •  | \n | (  o o  ) | \n  \\    O    /  !!"
            ]
        }
    }

    private static func ringmasterFrames(emotion: PetEmotion) -> [String] {
        switch emotion {
        case .happy:
            return [
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  ^     ^   )\n \\    ◡     / \n  \\_________/ ",
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  ◕     ◕   )\n \\    ▽     / \n  \\_________/ ",
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  ◠     ◠   )\n \\    ⌣     / \n  \\_________/ "
            ]
        case .cheer:
            return [
                "   _________   ✧\n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  ✪     ✪   )\n \\    ᗜ     /  ☆\n  \\_________/ ",
                "   _________   ★\n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  >     <   )\n \\    ㅂ     /  ✧\n  \\_________/ ",
                "   _________   ♪\n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  ^     ^   ) !\n \\    O     /  ★\n  \\_________/ "
            ]
        case .sleep:
            return [
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  -     -   )\n \\    ︶     / \n  \\_________/  zZ",
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  u     u   )\n \\    -     / \n  \\_________/  Zz",
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  ◡     ◡   )\n \\    -     / \n  \\_________/  zZ"
            ]
        case .concern:
            return [
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  •     •   )\n \\    ㅁ     / \n  \\_________/  ??",
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  °     °   )\n \\    _     / \n  \\_________/  ...",
                "   _________  \n  |         | \n  |_________| \n _|_|_|_|_|_|_\n(  •     •   )\n \\    o     / \n  \\_________/  !!"
            ]
        }
    }

    // MARK: Rat (쥐 — 자/子)

    private static func ratFrames(emotion: PetEmotion) -> [String] {
        switch emotion {
        case .happy:
            return [
                "  /\\____/\\\n (  ◕ ◕  )\n  >  ▽  <\n /|      |\\\n(_|      |_)",
                "  /\\____/\\\n (  ◠ ◠  )\n  >  ▿  <\n /|      |\\\n(_|      |_)",
                "  /\\____/\\\n (  ♥ ♥  )\n  >  ʊ  <\n /|      |\\\n(_|      |_)"
            ]
        case .cheer:
            return [
                "  /\\____/\\\n (  ◉ ◉  )\n  >  ▽  <  ✧\n /|      |\\☆\n(_|      |_)",
                "  /\\____/\\\n (  ✧ ✧  )\n  >  ◡  <  ★\n /|      |\\✦\n(_|      |_)",
                "  /\\____/\\\n (  ✪ ✪  )\n  >  ▿  <  ☆\n /|      |\\★\n(_|      |_)"
            ]
        case .sleep:
            return [
                "  /\\____/\\\n (  -  -  )\n  >  ᵕ  <\n /|      |\\\n(_|      |_)\n    zZz",
                "  /\\____/\\\n (  ‿  ‿  )\n  >  ᵕ  <\n /|      |\\\n(_|      |_)\n    Zzz",
                "  /\\____/\\\n (  ᐟ  ᐟ  )\n  >  ᵕ  <\n /|      |\\\n(_|      |_)\n    zZZ"
            ]
        case .concern:
            return [
                "  /\\____/\\\n (  •  •  )\n  >  ㅁ  <\n /|      |\\\n(_|      |_)\n    ...",
                "  /\\____/\\\n (  •ㅅ•  )\n  >  ㅂ  <\n /|      |\\\n(_|      |_)\n    ???",
                "  /\\____/\\\n (  •ө•  )\n  >  _   <\n /|      |\\\n(_|      |_)\n    ..."
            ]
        }
    }

    // MARK: Ox (소 — 축/丑)

    private static func oxFrames(emotion: PetEmotion) -> [String] {
        switch emotion {
        case .happy:
            return [
                "  ╱╲  ╱╲\n (    ◕ ◕    )\n  \\    ▽    /\n   \\======/\n    |    |",
                "  ╱╲  ╱╲\n (    ◠ ◠    )\n  \\    ▿    /\n   \\======/\n    |    |",
                "  ╱╲  ╱╲\n (    ♥ ♥    )\n  \\    ʊ    /\n   \\======/\n    |    |"
            ]
        case .cheer:
            return [
                "  ╱╲  ╱╲\n (    ◉ ◉    )  ✧\n  \\    ▽    /\n   \\======/  ☆\n    |    |",
                "  ╱╲  ╱╲\n (    ✧ ✧    )  ★\n  \\    ◡    /\n   \\======/  ✦\n    |    |",
                "  ╱╲  ╱╲\n (    ✪ ✪    )  ☆\n  \\    ▿    /\n   \\======/  ★\n    |    |"
            ]
        case .sleep:
            return [
                "  ╱╲  ╱╲\n (    -  -    )\n  \\    __    /\n   \\======/\n    |    |\n      zZz",
                "  ╱╲  ╱╲\n (    ‿  ‿    )\n  \\    __    /\n   \\======/\n    |    |\n      Zzz",
                "  ╱╲  ╱╲\n (    ᐟ  ᐟ    )\n  \\    __    /\n   \\======/\n    |    |\n      zZZ"
            ]
        case .concern:
            return [
                "  ╱╲  ╱╲\n (    •  •    )\n  \\    ㅁ    /\n   \\======/\n    |    |\n      ...",
                "  ╱╲  ╱╲\n (    •ㅅ•    )\n  \\    ㅂ    /\n   \\======/\n    |    |\n      ???",
                "  ╱╲  ╱╲\n (    •ө•    )\n  \\    _     /\n   \\======/\n    |    |\n      ..."
            ]
        }
    }

    // MARK: Tiger (호랑이 — 인/寅)

    private static func tigerFrames(emotion: PetEmotion) -> [String] {
        switch emotion {
        case .happy:
            return [
                " ╱╲  ╱╲\n(◕ ◕  ◕ ◕)\n |  ▽  |\n/|      |\\\n ||||||||||\n  \\      /",
                " ╱╲  ╱╲\n(◠ ◠  ◠ ◠)\n |  ▿  |\n/|      |\\\n ||||||||||\n  \\      /",
                " ╱╲  ╱╲\n(♥ ♥  ♥ ♥)\n |  ʊ  |\n/|      |\\\n ||||||||||\n  \\      /"
            ]
        case .cheer:
            return [
                " ╱╲  ╱╲\n(◉ ◉  ◉ ◉)  ✧\n |  ▽  |\n/|      |\\☆\n ||||||||||\n  \\      /",
                " ╱╲  ╱╲\n(✧ ✧  ✧ ✧)  ★\n |  ◡  |\n/|      |\\✦\n ||||||||||\n  \\      /",
                " ╱╲  ╱╲\n(✪ ✪  ✪ ✪)  ☆\n |  ▿  |\n/|      |\\★\n ||||||||||\n  \\      /"
            ]
        case .sleep:
            return [
                " ╱╲  ╱╲\n(- -  - -)\n |  __  |\n/|      |\\\n ||||||||||\n  \\      /\n    zZz",
                " ╱╲  ╱╲\n(‿ ‿  ‿ ‿)\n |  __  |\n/|      |\\\n ||||||||||\n  \\      /\n    Zzz",
                " ╱╲  ╱╲\n(ᐟ ᐟ  ᐟ ᐟ)\n |  __  |\n/|      |\\\n ||||||||||\n  \\      /\n    zZZ"
            ]
        case .concern:
            return [
                " ╱╲  ╱╲\n(• •  • •)\n |  ㅁ  |\n/|      |\\\n ||||||||||\n  \\      /\n    ...",
                " ╱╲  ╱╲\n(•ㅅ• •ㅅ•)\n |  ㅂ  |\n/|      |\\\n ||||||||||\n  \\      /\n    ???",
                " ╱╲  ╱╲\n(•ө• •ө•)\n |  _   |\n/|      |\\\n ||||||||||\n  \\      /\n    ..."
            ]
        }
    }

    // MARK: Rabbit (토끼 — 묘/卯)

    private static func rabbitFrames(emotion: PetEmotion) -> [String] {
        switch emotion {
        case .happy:
            return [
                "   \\  /\n   (◕ ◕)\n   ( ▽ )\n  /|   |\\\n (_|   |_)",
                "   \\  /\n   (◠ ◠)\n   ( ▿ )\n  /|   |\\\n (_|   |_)",
                "   \\  /\n   (♥ ♥)\n   ( ʊ )\n  /|   |\\\n (_|   |_)"
            ]
        case .cheer:
            return [
                "   \\  /\n   (◉ ◉)  ✧\n   ( ▽ )\n  /|   |\\☆\n (_|   |_)",
                "   \\  /\n   (✧ ✧)  ★\n   ( ◡ )\n  /|   |\\✦\n (_|   |_)",
                "   \\  /\n   (✪ ✪)  ☆\n   ( ▿ )\n  /|   |\\★\n (_|   |_)"
            ]
        case .sleep:
            return [
                "   \\  /\n   (- -)\n   ( __ )\n  /|   |\\\n (_|   |_)\n    zZz",
                "   \\  /\n   (‿ ‿)\n   ( __ )\n  /|   |\\\n (_|   |_)\n    Zzz",
                "   \\  /\n   (ᐟ ᐟ)\n   ( __ )\n  /|   |\\\n (_|   |_)\n    zZZ"
            ]
        case .concern:
            return [
                "   \\  /\n   (• •)\n   ( ㅁ )\n  /|   |\\\n (_|   |_)\n    ...",
                "   \\  /\n   (•ㅅ•)\n   ( ㅂ )\n  /|   |\\\n (_|   |_)\n    ???",
                "   \\  /\n   (•ө•)\n   ( _ )\n  /|   |\\\n (_|   |_)\n    ..."
            ]
        }
    }
}
