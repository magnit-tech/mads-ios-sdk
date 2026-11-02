//
//  MadsSentryHubFactory.swift
//  MadSDKSentry
//

import Foundation
import MadSDK
import Sentry

/// Отправляет диагностику MadSDK в проект Sentry SDK через отдельный `SentryHub`.
///
/// Следует рекомендации Sentry для библиотек внутри приложений
/// (https://docs.sentry.io/platforms/apple/configuration/shared-environments/):
/// не вызывает `SentrySDK.start` и не трогает глобальный hub, scope и интеграции приложения.
/// Собирается из исходников в приложении и линкуется с той же копией Sentry, что и приложение.
///
/// ```swift
/// MadsSDK.initialize(
///     sentry: MadsSentryHubFactory(),
///     imageLoader: MadsKingfisherImageLoader()
/// )
/// ```
///
/// Окружение событий — значение Sentry по умолчанию, `production`.
public struct MadsSentryHubFactory: MadsSentryFactory {

    public init() {}

    public func makeSentryClient(configuration: MadsSentryConfiguration) -> MadsSentryClient? {
        MadsSentryHubClient(configuration: configuration)
    }
}

final class MadsSentryHubClient: MadsSentryClient {

    private let hub: SentryHub
    /// `Options.urlSessionDelegate` хранит делегат слабой ссылкой — держим его сами.
    private let sessionDelegate: URLSessionDelegate?

    init?(configuration: MadsSentryConfiguration) {
        let sessionDelegate = TrustedCertificatesSessionDelegate(derCertificates: configuration.trustedCertificates)
        let options = Self.makeOptions(configuration: configuration, sessionDelegate: sessionDelegate)
        guard let client = SentryClient(options: options) else {
            return nil
        }
        self.sessionDelegate = sessionDelegate
        self.hub = SentryHub(client: client, andScope: nil)
    }

    static func makeOptions(configuration: MadsSentryConfiguration, sessionDelegate: URLSessionDelegate?) -> Options {
        let options = Options()
        options.dsn = configuration.dsn
        options.urlSessionDelegate = sessionDelegate
        // По умолчанию Sentry берёт релиз из main bundle, то есть версию приложения.
        options.releaseName = configuration.release
        // События приходят из корутины KMP: стек потока отправки — это `IOSSentry` и диспетчер корутин,
        // а не место ошибки. Настоящий стек Kotlin лежит в extras `stack_trace`.
        options.attachStacktrace = false
        // Для событий с исключениями Sentry прикрепляет стек потока и образы и при `attachStacktrace = false`.
        options.beforeSend = { event in
            event.threads = nil
            event.debugMeta = nil
            // Sentry сам подставляет номер сборки приложения в `dist` и имена его экранов в контекст `app`.
            // Релиз события — версия SDK, а экраны приложения к диагностике SDK не относятся.
            event.dist = nil
            event.context?["app"]?.removeValue(forKey: "view_names")
            return event
        }
        return options
    }

    func capture(event: MadsSentryEvent) {
        hub.capture(event: Event(madsEvent: event))
    }
}

extension Event {

    convenience init(madsEvent: MadsSentryEvent) {
        self.init(level: SentryLevel(madsLevel: madsEvent.level))
        message = SentryMessage(formatted: madsEvent.message)
        timestamp = madsEvent.timestamp
        tags = madsEvent.tags
        extra = madsEvent.extras
        if !madsEvent.exceptions.isEmpty {
            // Sentry ждёт цепочку от самой ранней причины к самому исключению.
            exceptions = madsEvent.exceptions.reversed().map { exception in
                Exception(value: exception.value, type: exception.type)
            }
        }
    }
}

extension SentryLevel {

    init(madsLevel: MadsSentryEvent.Level) {
        switch madsLevel {
        case .error:
            self = .error
        case .info:
            self = .info
        }
    }
}
