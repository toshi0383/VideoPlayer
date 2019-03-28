import AVFoundation
import RxCocoa
import RxSwift

@available(iOS 9.3, *)
final class MetadataCollectorDelegate: NSObject, AVPlayerItemMetadataCollectorPushDelegate {

    let metadataDebugInfo = PublishRelay<String>()

    public func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector,
                                  didCollect metadataGroups: [AVDateRangeMetadataGroup],
                                  indexesOfNewGroups: IndexSet,
                                  indexesOfModifiedGroups: IndexSet) {
        let s = "[In-Playlist Timed Meta]\n \(metadataGroups)"

        print("[metadataCollector]: \(metadataCollector)")
        print("[metadataGroups]: \(s)")
        print("[indexesOfNewGroups]: \(indexesOfNewGroups)")
        print("[indexesOfModifiedGroups]: \(indexesOfModifiedGroups)")

        metadataDebugInfo.accept(s)
    }
}
