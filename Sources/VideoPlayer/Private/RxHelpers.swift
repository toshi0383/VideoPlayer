import RxSwift

func void<E>(_ x: E) {
    return Void()
}

extension Disposable {

    /// Adds `self` to `compositeDisposable`.
    func disposed(by compositeDisposable: CompositeDisposable) {
        _ = compositeDisposable.insert(self)
    }

}
