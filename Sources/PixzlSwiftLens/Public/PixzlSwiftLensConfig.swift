import SwiftUI

public enum PixzlSwiftLensActivator: Sendable, Equatable {
    case shake
    case threeFingerTap
    case floatingButton
}

public struct PixzlSwiftLensPanels: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let performance = PixzlSwiftLensPanels(rawValue: 1 << 0)
    public static let network     = PixzlSwiftLensPanels(rawValue: 1 << 1)
    public static let logs        = PixzlSwiftLensPanels(rawValue: 1 << 2)

    public static let all: PixzlSwiftLensPanels = [.performance, .network, .logs]
}

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

public enum PixzlSwiftLensPillStyle: Sendable {
    case compact
    case detailed
    case hidden
}

public struct PixzlSwiftLensConfig: Sendable {
    public var activator: PixzlSwiftLensActivator
    public var panels: PixzlSwiftLensPanels
    public var position: PixzlSwiftLensPosition
    public var pillStyle: PixzlSwiftLensPillStyle

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
