//
//  TrustedCertificatesSessionDelegate.swift
//  MadSDKSentry
//

import Foundation
import Security

/// Доверяет серверу Sentry, если цепочка проходит проверку системными корнями или дополнительными сертификатами.
///
/// Сначала идёт обычная проверка, при её провале — повторная с дополнительными корнями.
/// Проверка имени хоста остаётся в силе.
final class TrustedCertificatesSessionDelegate: NSObject, URLSessionDelegate {

    private let anchors: [SecCertificate]

    /// - Returns: `nil`, если дополнительных сертификатов нет — тогда работает стандартная проверка.
    init?(derCertificates: [Data]) {
        let anchors = derCertificates.compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
        guard !anchors.isEmpty else {
            return nil
        }
        self.anchors = anchors
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        guard isTrusted(serverTrust) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }

    private func isTrusted(_ serverTrust: SecTrust) -> Bool {
        if SecTrustEvaluateWithError(serverTrust, nil) {
            return true
        }
        SecTrustSetAnchorCertificates(serverTrust, anchors as CFArray)
        SecTrustSetAnchorCertificatesOnly(serverTrust, false)
        return SecTrustEvaluateWithError(serverTrust, nil)
    }
}
