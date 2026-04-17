import UIKit
import MadSDK

final class InAppViewController: UIViewController {
    // Экземпляр загрузчика, используемый для запроса in-app рекламы.
    private let loader = InAppAdLoader()
    // Последний успешно загруженный рекламный объект.
    private var ad: InAppAd?

    private let loadButton = UIButton(type: .system)
    private let showButton = UIButton(type: .system)
    private let stackView = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "InApp Ad"

        setupStackView()
        setupButtons()
    }

    // MARK: - Private Methods

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 33),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -33)
        ])
    }

    private func setupButtons() {
        loadButton.setTitle("Load ad", for: .normal)
        loadButton.addTarget(self, action: #selector(didTapLoad), for: .touchUpInside)

        showButton.setTitle("Show", for: .normal)
        showButton.addTarget(self, action: #selector(didTapShow), for: .touchUpInside)
        showButton.isEnabled = false

        stackView.addArrangedSubview(loadButton)
        stackView.addArrangedSubview(showButton)

        [loadButton, showButton].forEach { button in
            button.backgroundColor = .red
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
            button.clipsToBounds = true
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }

    @objc
    private func didTapLoad() {
        showButton.isEnabled = false
        ad = nil

        // Делегат назначается до запуска загрузки для получения результата запроса.
        loader.delegate = self
        let request = InAppAdRequest(
            padId: "44", // тестовый padId, реальный будет доступен в админке
            targetings: [:],
            isDebugCreativeEnabled: true // ключ, чтобы всегда возвращать тестовый креатив
        )
        // Запускается асинхронная загрузка рекламного объекта.
        loader.load(request)
    }

    @objc
    private func didTapShow() {
        guard let ad = ad else {
            return
        }

        // Делегат назначается перед показом для получения событий жизненного цикла и действий пользователя.
        ad.delegate = self
        // Показ рекламного объекта выполняется через публичный API SDK.
        MadsSDK.showInAppAd(ad, inVC: self)
    }
}

// MARK: - InAppAdLoaderDelegate

extension InAppViewController: InAppAdLoaderDelegate {
    func inAppAdLoader(_ loader: any InAppAdLoaderProtocol, didReceive response: InAppAdLoader.Response) {
        switch response {
        case let .success(ad, _):
            // Успешно загруженный объект сохраняется для последующего показа.
            self.ad = ad
            showButton.isEnabled = true
        case let .failure(error, _):
            print("InApp ad load failed: \(error.localizedDescription)")
            showButton.isEnabled = false
        case .noContent:
            print("InApp ad load no content")
            showButton.isEnabled = false
        @unknown default:
            break
        }
    }
}

// MARK: - InAppAdDelegate

extension InAppViewController: InAppAdDelegate {
    func inAppAd(_ ad: InAppAd, didEmit event: InAppAd.Event) {
        // События отражают жизненный цикл показа рекламного креатива.
        switch event {
        case let .onCreativeView(info):
            print("InAppAd shown. Creative: \(info.creativeId ?? "n/a")")
        case let .onCreativeFailedToShow(info):
            print("InAppAd failed to show. Creative: \(info.creativeId ?? "n/a")")
        case let .onCreativeDismissed(info, type):
            print("InAppAd dismissed. Type: \(type.rawValue), creative: \(info.creativeId ?? "n/a")")
        @unknown default:
            break
        }
    }

    func inAppAd(_ ad: InAppAd, didEmit action: InAppAd.Action) {
        // Действия отражают пользовательские взаимодействия внутри рекламного креатива.
        switch action {
        case let .onUrlClicked(info, url):
            print("URL clicked: \(url), creative: \(info.creativeId ?? "n/a")")
        case let .onPromocodeCopy(info, promocode):
            print("Promocode copied: \(promocode), creative: \(info.creativeId ?? "n/a")")
        @unknown default:
            break
        }
    }
}
