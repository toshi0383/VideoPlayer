import Foundation
import RxSwift

public struct Namespace<Base> {
    /// Base object to extend.
    let base: Base

    /// Creates extensions with base object.
    ///
    /// - parameter base: Base object.
    init(_ base: Base) {
        self.base = base
    }
}

/// A type that has rxav extensions.
public protocol NamespaceCompatible {
    /// Extended type
    /// - Note: 名前が `CompatibleType` だと、他の同名associatedtypeとコンフリクトするリスクがある
    associatedtype NamespaceCompatibleType

    /// Namespace extensions.
    static var rxav: Namespace<NamespaceCompatibleType>.Type { get set }

    /// Namespace extensions.
    var rxav: Namespace<NamespaceCompatibleType> { get set }
}

extension NamespaceCompatible {
    /// Namespace extensions.
    public static var rxav: Namespace<Self>.Type {
        get {
            return Namespace<Self>.self
        }
        set {
            // this enables using Namespace to "mutate" base type
        }
    }

    /// Namespace extensions.
    public var rxav: Namespace<Self> {
        get {
            return Namespace(self)
        }
        set {
            // this enables using Namespace to "mutate" base object
        }
    }
}

/// Extend NSObject with `rxav` proxy.
extension NSObject: NamespaceCompatible { }

// Realm.Notificationと区別するため念のためFoundation prefix.
extension Foundation.Notification.Name: NamespaceCompatible { }
