//
// Copyright (c) Vatsal Manot
//

import Merge
import Foundation
import SwiftUIX

public struct ViewTransition: ViewTransitionContext {
    public enum Error: Swift.Error {
        case cannotPopRoot
        case isRoot
        case nothingToDismiss
        case navigationControllerMissing
        case cannotSetRoot
    }
    
    private var payload: Payload
    
    @usableFromInline
    var animated: Bool = true
    @usableFromInline
    var payloadViewName: AnyHashable?
    @usableFromInline
    var payloadViewType: Any.Type?
    @usableFromInline
    var environmentInsertions: EnvironmentInsertions
    
    @usableFromInline
    init(payload: (AnyPresentationView) -> ViewTransition.Payload, view: AnyPresentationView) {
        self.payload = payload(view)
        self.payloadViewType = type(of: view)
        self.environmentInsertions = .init()
    }
    
    @usableFromInline
    init<V: View>(payload: (AnyPresentationView) -> ViewTransition.Payload, view: V) {
        self.init(payload: payload, view: .init(view))
    }
    
    @usableFromInline
    init(payload: ViewTransition.Payload) {
        self.payload = payload
        self.payloadViewName = nil
        self.payloadViewType = nil
        self.environmentInsertions = .init()
    }
    
    @usableFromInline
    func finalize() -> Payload {
        var result = payload
        
        result.mutateViewInPlace({
            $0.environmentInPlace(environmentInsertions)
        })
        
        return result
    }
}

extension ViewTransition {
    public var revert: ViewTransition? {
        switch payload {
            case .present:
                return .dismiss
            case .replace:
                return nil
            case .dismiss:
                return nil
            case .dismissView:
                return nil
            case .push:
                return .pop
            case .pushOrPresent:
                return .popOrDismiss
            case .pop:
                return nil
            case .popToRoot:
                return nil
            case .popOrDismiss:
                return nil
            case .popToRootOrDismiss:
                return nil
            case .set:
                return nil
            case .setRoot:
                return nil
            case .linear:
                return nil
            case .custom:
                return nil
            case .none:
                return ViewTransition.none
        }
    }
}

// MARK: - Conformances -

extension ViewTransition: CustomStringConvertible {
    public var description: String {
        switch payload {
            case .present:
                return "Present"
            case .replace:
                return "Replace"
            case .dismiss:
                return "Dismiss"
            case .dismissView(let name):
                return "Dismiss \(name)"
            case .push:
                return "Push"
            case .pushOrPresent:
                return "Push or present"
            case .pop:
                return "Pop"
            case .popToRoot:
                return "Pop to root"
            case .popOrDismiss:
                return "Pop or dismiss"
            case .popToRootOrDismiss:
                return "Pop to root or dismiss"
            case .set:
                return "Set"
            case .setRoot:
                return "Set root"
            case .linear:
                return "Linear"
            case .custom:
                return "Custom"
            case .none:
                return "None"
        }
    }
}

// MARK: - API -

extension ViewTransition {
    @inlinable
    public static func present<V: View>(_ view: V) -> ViewTransition {
        .init(payload: ViewTransition.Payload.present, view: view)
    }
    
    @inlinable
    public static func present(_ view: AnyPresentationView) -> ViewTransition {
        .init(payload: ViewTransition.Payload.present, view: view)
    }
    
    @inlinable
    public static func replace<V: View>(with view: V) -> ViewTransition {
        .init(payload: ViewTransition.Payload.replace, view: view)
    }
    
    @inlinable
    public static func replace(with view: AnyPresentationView) -> ViewTransition {
        .init(payload: ViewTransition.Payload.replace, view: view)
    }
    
    @inlinable
    public static var dismiss: ViewTransition {
        .init(payload: .dismiss)
    }
    
    @inlinable
    public static func dismissView<H: Hashable>(named name: H) -> ViewTransition {
        .init(payload: .dismissView(named: .init(name)))
    }
    
    @inlinable
    public static func push<V: View>(_ view: V) -> ViewTransition {
        .init(payload: ViewTransition.Payload.push, view: view)
    }
    
    @inlinable
    public static func push(_ view: AnyPresentationView) -> ViewTransition {
        .init(payload: ViewTransition.Payload.push, view: view)
    }
    
    @inlinable
    public static func pushOrPresent<V: View>(_ view: V) -> ViewTransition {
        .init(payload: ViewTransition.Payload.pushOrPresent, view: view)
    }
    
    @inlinable
    public static func pushOrPresent(_ view: AnyPresentationView) -> ViewTransition {
        .init(payload: ViewTransition.Payload.pushOrPresent, view: view)
    }
    
    @inlinable
    public static var pop: ViewTransition {
        .init(payload: .pop)
    }
    
    @inlinable
    public static var popToRoot: ViewTransition {
        .init(payload: .popToRoot)
    }
    
    @inlinable
    public static var popOrDismiss: ViewTransition {
        .init(payload: .popOrDismiss)
    }
    
    @inlinable
    public static var popToRootOrDismiss: ViewTransition {
        .init(payload: .popToRootOrDismiss)
    }
    
    @inlinable
    public static func set<V: View>(_ view: V) -> ViewTransition {
        .init(payload: ViewTransition.Payload.set, view: view)
    }
    
    @inlinable
    public static func set(_ view: AnyPresentationView) -> ViewTransition {
        .init(payload: ViewTransition.Payload.set, view: view)
    }
    
    @inlinable
    public static func setRoot<V: View>(_ view: V) -> ViewTransition {
        .init(payload: ViewTransition.Payload.setRoot, view: view)
    }
    
    @inlinable
    public static func setRoot(_ view: AnyPresentationView) -> ViewTransition {
        .init(payload: ViewTransition.Payload.setRoot, view: view)
    }
    
    @inlinable
    public static func linear(_ transitions: [ViewTransition]) -> ViewTransition {
        .init(payload: .linear(transitions))
    }
    
    @inlinable
    public static func linear(_ transitions: ViewTransition...) -> ViewTransition {
        linear(transitions)
    }
    
    @inlinable
    internal static func custom(
        _ body: @escaping () -> AnyPublisher<ViewTransitionContext, Swift.Error>
    ) -> ViewTransition {
        .init(payload: .custom(body))
    }

    @available(*, deprecated, renamed: "custom")
    internal static func dynamic(
        _ body: @escaping () -> Void
    ) -> ViewTransition {
        .custom(body)
    }

    public static func custom(
        _ body: @escaping () -> Void
    ) -> ViewTransition {
        // FIXME: Set a correct view transition context.
        struct CustomViewTransitionContext: ViewTransitionContext {

        }

        return .custom { () -> AnyPublisher<ViewTransitionContext, Swift.Error> in
            Deferred {
                Future<ViewTransitionContext, Swift.Error> { attemptToFulfill in
                    body()
                    
                    attemptToFulfill(.success(CustomViewTransitionContext()))
                }
            }
            .eraseToAnyPublisher()
        }
    }

    @inlinable
    public static var none: ViewTransition {
        .init(payload: .none)
    }
}

extension ViewTransition {
    public func environment(_ builder: EnvironmentInsertions) -> ViewTransition {
        var result = self
        
        result.environmentInsertions.merge(builder)
        
        return result
    }
    
    public func mergeCoordinator<VC: ViewCoordinator>(_ coordinator: VC) -> Self {
        self.environment(.object(coordinator))
            .environment(.object(AnyViewCoordinator(coordinator)))
    }
}

// MARK: - Helpers -

extension ViewTransition.Payload {
    mutating func mutateViewInPlace(_ body: (inout AnyPresentationView) -> Void) {
        switch self {
            case .linear(let transitions):
                self = .linear(transitions.map({
                    var transition = $0
                    
                    transition.mutateViewInPlace(body)
                    
                    return transition
                }))
            default: do {
                if var view = self.view {
                    body(&view)
                    
                    self.view = view
                }
            }
        }
    }
}

extension ViewTransition {
    mutating func mutateViewInPlace(_ body: (inout AnyPresentationView) -> Void) {
        switch payload {
            case .linear(let transitions):
                payload = .linear(transitions.map({
                    var transition = $0
                    
                    transition.mutateViewInPlace(body)
                    
                    return transition
                }))
            default: do {
                if var view = payload.view {
                    body(&view)
                    
                    payload.view = view
                }
            }
        }
    }
}
