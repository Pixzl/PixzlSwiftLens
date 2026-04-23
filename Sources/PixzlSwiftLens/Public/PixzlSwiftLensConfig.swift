import SwiftUI

/// How the user opens the expanded HUD.
///
/// `.shake` reacts to UIDevice motion shakes, `.threeFingerTap` to a three-finger
/// tap gesture, `.floatingButton` renders a draggable button in place of the pill.
public enum PixzlSwiftLensActivator: Sendable, Equatable {
    case shake
    case threeFingerTap
    case floatingButton
}

/// Set of panels to surface in the expanded HUD. Combine with set algebra.
///
///     .pixzlSwiftLens(panels: [.performance, .network])
public struct PixzlSwiftLensPanels: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let performance = PixzlSwiftLensPanels(rawValue: 1 << 0)
    public static let network     = PixzlSwiftLensPanels(rawValue: 1 << 1)
    public static let logs        = PixzlSwiftLensPanels(rawValue: 1 << 2)
    /// Live body-invalidation rates for Views annotated with `.lensTrack(_:)`.
    public static let views       = PixzlSwiftLensPanels(rawValue: 1 << 3)

    public static let all: PixzlSwiftLensPanels = [.performance, .network, .logs, .views]
}

/// Screen corner the collapsed pill docks to.
public enum PixzlSwiftLensPosition: Sendable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var alignment: Alignment {
        switch self {
        case .topLeading:     .topLeading
        case .topTrailing:    .topTrailing
        case .bottomLeading:  .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }
}

/// Visual style for the collapsed pill.
///
/// `.compact` shows FPS only; `.detailed` shows FPS / MEM / CPU; `.hidden`
/// suppresses the pill entirely (useful with `.floatingButton`).
public enum PixzlSwiftLensPillStyle: Sendable {
    case compact
    case detailed
    case hidden
}

/// Immutable configuration for the debug HUD. Build once and pass to `pixzlSwiftLens`.
///
/// A new value must be created for any change to take effect — the modifier captures
/// the config at init and does not observe mutations.
public struct PixzlSwiftLensConfig: Sendable {
    public let activator: PixzlSwiftLensActivator
    public let panels: PixzlSwiftLensPanels
    public let position: PixzlSwiftLensPosition
    public let pillStyle: PixzlSwiftLensPillStyle

    public init(
        activator: PixzlSwiftLensActivator = .shake,
        panels: PixzlSwiftLensPanels = .all,
        position: PixzlSwiftLensPosition = .topTrailing,
        pillStyle: PixzlSwiftLensPillStyle = .compact
    ) {
        self.activator = activator
        self.panels = panels
        self.position = position
        self.pillStyle = pillStyle
    }
}
