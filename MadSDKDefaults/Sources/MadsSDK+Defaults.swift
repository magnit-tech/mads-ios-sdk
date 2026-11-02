//
//  MadsSDK+Defaults.swift
//  MadSDKDefaults
//

@_exported import MadSDK
@_exported import MadSDKKingfisher
@_exported import MadSDKSentry
@_spi(Internal) import MadSDK

extension MadsSDK {

    /// `MadsSDK.initialize` с готовыми реализациями по умолчанию: диагностика через `MadsSentryHubFactory`,
    /// загрузка картинок через `MadsKingfisherImageLoader`. Любую из них приложение может заменить своей.
    ///
    /// ```swift
    /// import MadSDKDefaults
    ///
    /// MadsSDK.initialize()                                // Sentry и Kingfisher
    /// MadsSDK.initialize(sentry: nil)                     // без Sentry
    /// MadsSDK.initialize(imageLoader: MyImageLoader())    // свой загрузчик картинок
    /// ```
    ///
    /// Компилятор выбирает эту перегрузку, а не `initialize` из `MadSDK`, и не сообщает о неоднозначности.
    /// Если файл импортирует только `MadSDKDefaults`, она затеняет `initialize` из `MadSDK`, который этот модуль
    /// импортирует. Если файл импортирует и `MadSDK`, затенения нет, но там `imageLoader` generic,
    /// а из равных кандидатов компилятор берёт негенерик.
    public static func initialize(
        adRequestTimeoutMillis: Int64 = 10_000,
        sentry: MadsSentryFactory? = MadsSentryHubFactory(),
        imageLoader: MadsImageLoader = MadsKingfisherImageLoader()
    ) {
        start(adRequestTimeoutMillis: adRequestTimeoutMillis, sentry: sentry, imageLoader: imageLoader)
    }
}
