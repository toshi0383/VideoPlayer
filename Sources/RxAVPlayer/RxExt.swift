import RxSwift

protocol OptionalType {
    associatedtype Wrapped

    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    var value: Wrapped? { return self }
}

extension ObservableType where E: OptionalType {

    func filterNil() -> Observable<E.Wrapped> {
        return flatMap { item -> Observable<E.Wrapped> in
            if let value = item.value {
                return Observable.just(value)
            } else {
                return Observable.empty()
            }
        }
    }

}
