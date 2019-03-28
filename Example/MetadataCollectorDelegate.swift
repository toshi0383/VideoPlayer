import AVFoundation

@available(iOS 9.3, *)
final class MetadataCollectorDelegate: NSObject, AVPlayerItemMetadataCollectorPushDelegate {
    public func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector,
                                  didCollect metadataGroups: [AVDateRangeMetadataGroup],
                                  indexesOfNewGroups: IndexSet,
                                  indexesOfModifiedGroups: IndexSet) {
        print("[metadataCollector]: \(metadataCollector)")
        print("[metadataGroups]: \(metadataGroups)")
        print("[indexesOfNewGroups]: \(indexesOfNewGroups)")
        print("[indexesOfModifiedGroups]: \(indexesOfModifiedGroups)")
    }
}
