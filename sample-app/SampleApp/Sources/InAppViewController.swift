import UIKit
import MadSDK

final class InAppViewController: UIViewController {
    private let loader = InAppAdLoader()
    private var ad: InAppAd?

    private let loadButton = UIButton(type: .system)
    private let showButton = UIButton(type: .system)
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "InApp Ad"

        setupStackView()
        setupButtons()
    }

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

        loader.delegate = self
        loader.load(
            padId: 1, // тестовый padId, реальный будет доступен в админке
            targetings: [:],
            isDebugCreativeEnabled: true // ключ, чтобы всегда возвращать тестовый креатив
        )
    }

    @objc
    private func didTapShow() {
        guard let ad = ad else {
            return
        }

        ad.delegate = self
        MadsSDK.showInAppAd(ad, inVC: self)
    }
}

extension InAppViewController: InAppAdLoaderDelegate {
    func inAppAdLoader(_ loader: any InAppAdLoaderProtocol, didChangeState state: InAppAdLoader.State) {
        switch state {
        case let .loaded(ad):
            self.ad = ad
            showButton.isEnabled = true
        case let .failed(error):
            print("InApp ad load failed: \(error.localizedDescription)")
            showButton.isEnabled = false
        @unknown default:
            break
        }
    }
}

extension InAppViewController: InAppAdDelegate {
    func inAppAd(_ ad: InAppAd, didEmit event: InAppAd.Event) {
        switch event {
        case .adShown:
            print("InAppAd shown")
        case .adFailedToShow:
            print("InAppAd failed to show")
        case let .adDeeplinkClicked(deeplink):
            print("Deeplink clicked: \(deeplink)")
        case let .adPromocodeClicked(promocode):
            print("Promocode clicked: \(promocode)")
        case .adDismissed:
            print("InAppAd dismissed")
        @unknown default:
            break
        }
    }
}


