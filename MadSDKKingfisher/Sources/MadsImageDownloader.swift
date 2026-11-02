import Foundation
import Kingfisher
@_spi(Internal) import MadSDK

/// Сетевой загрузчик картинок SDK — отдельный от `ImageDownloader.default` приложения.
///
/// Проверяет сертификат сервера через `ServerTrustEvaluator`: системные корни, при отказе — ещё и корни SDK
/// (корень Минцифры). Загрузчик приложения и его настройки не меняются; кэш остаётся общим `ImageCache.default`.
///
/// Проверка срабатывает только для доменов, которым приложение ослабило ATS
/// (`NSExceptionAllowsInsecureHTTPLoads`): для остальных iOS обрывает соединение до неё.
enum MadsImageDownloader {

    /// Опции Kingfisher, с которыми адаптер отправляет каждый запрос в сеть.
    static let options: KingfisherOptionsInfo = [.downloader(shared)]

    static let shared: ImageDownloader = {
        let downloader = ImageDownloader(name: "MadSDK")
        downloader.authenticationChallengeResponder = responder
        return downloader
    }()

    /// `ImageDownloader.authenticationChallengeResponder` держит обработчик слабо, поэтому он хранится здесь.
    private static let responder = ServerTrustChallengeResponder()
}

/// Отвечает на challenge загрузчика картинок по правилам `ServerTrustEvaluator`.
final class ServerTrustChallengeResponder: AuthenticationChallengeResponsible {

    private let evaluator: ServerTrustEvaluator

    init(evaluator: ServerTrustEvaluator = .default) {
        self.evaluator = evaluator
    }

    func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        evaluator.disposition(for: challenge)
    }

    func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        evaluator.disposition(for: challenge)
    }
}
