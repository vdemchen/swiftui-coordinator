import SwiftUI
import Observation

// MARK: - Coordinator
@MainActor public protocol Coordinator: AnyObject, Observable {
    associatedtype PathType: Hashable
    associatedtype RootType: Hashable = Never
    associatedtype PresentType: Identifiable = Never

    var path: NavigationPath { get set }
    var presented: PresentType? { get set }
    var rootState: RootType { get set }
    var presentedQueue: [PresentType] { get set }

    func push(_ route: PathType)
    func pop()
    func popToRoot()
    func set(_ state: RootType)
    func present(_ type: PresentType)
    func dismiss()
    func presentLast()
}

// MARK: - Presented Never
public extension Coordinator where PresentType == Never {
    var presented: Never? {
        get { nil }
        set { }
    }
    var presentedQueue: [Never] {
        get { [] }
        set { }
    }

    func present(_ type: Never) { }
    func dismiss() { }
    func presentLast() { }
}

// MARK: - RootType Never
public extension Coordinator where RootType == Never {
    var rootState: Never {
        get { fatalError("Coordinator created without root view. Check your conformences.") }
        set { }
    }
    func set(_ state: Never) { }
}

// MARK: - Default
public extension Coordinator {
    func push(_ route: PathType) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func present(_ type: PresentType) {
        if let presented {
            presentedQueue.append(presented)
        }

        presented = type
    }

    func presentLast() {
        if !presentedQueue.isEmpty {
            let lastItem = presentedQueue.removeLast()
            presented = lastItem
        } else {
            presented = nil
        }
    }

    func dismiss() {
        presented = nil
    }

    func set(_ state: RootType) {
        path = .init()
        rootState = state
    }
}
