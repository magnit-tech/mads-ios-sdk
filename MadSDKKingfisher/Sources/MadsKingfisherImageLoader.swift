import Kingfisher
@_spi(Internal) import MadSDK
import UIKit

/// Загрузчик картинок MadSDK на Kingfisher приложения.
///
/// Собирается из исходников в приложении и линкуется с той же копией Kingfisher, что и приложение:
/// в `MadSDK.xcframework` Kingfisher не входит, поэтому в процессе одна копия его классов и один кэш.
/// В сеть ходит через свой загрузчик `MadsImageDownloader`, а не через `ImageDownloader.default` приложения.
///
/// ```swift
/// MadsSDK.initialize(imageLoader: MadsKingfisherImageLoader())
/// ```
@MainActor
public final class MadsKingfisherImageLoader: MadsImageLoader {

    public nonisolated init() {}

    // MARK: - Cache Check

    public func isCached(_ url: URL) -> Bool {
        ImageCache.default.isCached(forKey: url.cacheKey)
    }

    // MARK: - Single Image Load

    @discardableResult
    public func loadImage(
        _ url: URL,
        priority: Float,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) -> Cancellable? {
        let options: KingfisherOptionsInfo = [
            .downloadPriority(priority),
            .cacheOriginalImage
        ] + MadsImageDownloader.options
        let task = KingfisherManager.shared.retrieveImage(with: url, options: options) { result in
            switch result {
            case .success(let value):
                completion(.success(value.image))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task.map { KingfisherCancellable(task: $0) }
    }

    // MARK: - Batch Prefetch

    public func prefetch(_ urls: [URL], completion: @escaping () -> Void) -> Cancellable {
        guard !urls.isEmpty else {
            completion()
            return NoOpCancellable()
        }

        let prefetcher = ImagePrefetcher(
            urls: urls,
            options: [.downloadPriority(URLSessionTask.defaultPriority)] + MadsImageDownloader.options,
            completionHandler: makeLoggingHandler(completion)
        )
        prefetcher.maxConcurrentDownloads = 5
        prefetcher.start()
        return PrefetcherCancellable(prefetcher: prefetcher)
    }

    // MARK: - Set Image on View

    @discardableResult
    public func setImage(
        on imageView: UIImageView,
        url: URL,
        placeholder: UIImage?,
        options: [MadsImageLoadingOption],
        completion: ((Bool) -> Void)?
    ) -> Cancellable? {
        let kfOptions = options.compactMap(\.kingfisherOption) + [.cacheOriginalImage] + MadsImageDownloader.options
        let task = imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: kfOptions
        ) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure(let error):
                MadsSDK.log("ImageService", "Failed: \(error.localizedDescription)")
                completion?(false)
            }
        }
        return task.map { KingfisherCancellable(task: $0) }
    }
}

// MARK: - Logging

private extension MadsKingfisherImageLoader {

    func makeLoggingHandler(
        _ completion: @escaping () -> Void,
        startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    ) -> (([Resource], [Resource], [Resource]) -> Void) {
        { skipped, failed, completed in
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let total = skipped.count + failed.count + completed.count
            MadsSDK.log(
                "🖼️ Prefetch",
                "✅ \(total) изображений за \(String(format: "%.2f", duration))s | " +
                "загружено: \(completed.count), в кэше: \(skipped.count), ошибок: \(failed.count)"
            )
            completion()
        }
    }
}

// MARK: - Cancellable Wrappers

private struct KingfisherCancellable: Cancellable {
    let task: DownloadTask

    func cancel() {
        task.cancel()
    }
}

private struct PrefetcherCancellable: Cancellable {
    let prefetcher: ImagePrefetcher

    func cancel() {
        prefetcher.stop()
    }
}

// MARK: - MadsImageLoadingOption → Kingfisher Mapping

private extension MadsImageLoadingOption {
    var kingfisherOption: KingfisherOptionsInfoItem? {
        switch self {
        case .transition(let transition):
            switch transition {
            case .none:               return .transition(.none)
            case .fade(let duration): return .transition(.fade(duration))
            // MadSDK приходит бинарём и может оказаться новее адаптера: незнакомую опцию пропускаем.
            @unknown default:         return nil
            }
        case .priority(let priority):       return .downloadPriority(priority)
        case .backgroundDecode:             return .backgroundDecode
        case .keepCurrentImageWhileLoading: return .keepCurrentImageWhileLoading
        @unknown default:                   return nil
        }
    }
}
