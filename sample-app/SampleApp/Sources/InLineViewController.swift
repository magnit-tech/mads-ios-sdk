import UIKit
import MadSDK

final class InLineViewController: UIViewController {
    // Провайдер, отвечающий за загрузку inline-рекламы и предоставление представления для отображения.
    private let adProvider = InlineAdProvider()

    private struct AdPlacement {
        let buttonTitle: String
        let padId: String
    }

    private let placements: [AdPlacement] = [
        .init(buttonTitle: "Load carousel", padId: "46"),
        .init(buttonTitle: "Load single", padId: "48")
    ]

    private var adContainersByPadId: [String: UIView] = [:]
    private var statusLabelsByPadId: [String: UILabel] = [:]

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "InLine Ad"

        setupProvider()
        setupViews()
    }

    // MARK: - Private Methods

    private func setupProvider() {
        // Делегаты назначаются для получения результатов загрузки, событий и действий пользователя.
        adProvider.loadingDelegate = self
        adProvider.delegate = self
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        placements.enumerated().forEach { index, placement in
            stackView.addArrangedSubview(makePlacementSection(placement: placement, index: index))
        }

        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: frameGuide.widthAnchor)
        ])
    }

    private func makePlacementSection(placement: AdPlacement, index: Int) -> UIView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.alignment = .fill
        sectionStack.distribution = .fill
        sectionStack.spacing = 12

        let button = UIButton(type: .system)
        button.setTitle(placement.buttonTitle, for: .normal)
        button.tag = index
        button.addTarget(self, action: #selector(didTapLoad(_:)), for: .touchUpInside)
        button.backgroundColor = .red
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            button.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            button.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 320),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        let adContainer = UIView()
        adContainer.backgroundColor = .clear
        adContainer.layer.cornerRadius = 8
        adContainer.clipsToBounds = true

        let statusLabel = UILabel()
        statusLabel.text = "Tap button to load"
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        adContainer.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: adContainer.topAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor, constant: -12)
        ])

        sectionStack.addArrangedSubview(buttonContainer)
        sectionStack.addArrangedSubview(adContainer)

        // Для каждого padId сохраняются отдельные контейнер и статусный label.
        adContainersByPadId[placement.padId] = adContainer
        statusLabelsByPadId[placement.padId] = statusLabel

        return sectionStack
    }

    @objc
    private func didTapLoad(_ sender: UIButton) {
        guard placements.indices.contains(sender.tag) else {
            return
        }

        let slot = AdSlot(padId: placements[sender.tag].padId)
        loadAd(for: slot)
    }

    private func loadAd(for slot: AdSlot) {
        setStatus("Loading inline ad...", for: slot, color: .secondaryLabel)
        guard let adContainer = adContainersByPadId[slot.padId], let statusLabel = statusLabelsByPadId[slot.padId] else {
            return
        }

        // Перед новой загрузкой контейнер очищается от ранее отображенного рекламного представления.
        adContainer.subviews.forEach { view in
            if view !== statusLabel {
                view.removeFromSuperview()
            }
        }

        let request = InlineAdRequest(
            // `AdSlot` идентифицирует placement, настроенный в административном интерфейсе.
            slot: slot,
            targetings: [:],
            isDebugCreativeEnabled: true
        )
        // Результат загрузки возвращается асинхронно через `InlineAdProviderLoadingDelegate`.
        adProvider.load(request)
    }

    private func renderAd(for slot: AdSlot) {
        guard let adContainer = adContainersByPadId[slot.padId], let statusLabel = statusLabelsByPadId[slot.padId] else {
            return
        }

        // SDK формирует готовое представление, которое остается встроить в иерархию экрана.
        guard let adView = adProvider.view(for: slot, in: self) else {
            showError("Failed to render inline ad view", for: slot)
            return
        }

        statusLabel.removeFromSuperview()
        adContainer.subviews.forEach { $0.removeFromSuperview() }
        adContainer.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = adView.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor)
        bottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: adContainer.topAnchor),
            adView.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor),
            bottomConstraint
        ])
    }

    private func showError(_ message: String, for slot: AdSlot) {
        setStatus("Error: \(message)", for: slot, color: .systemRed)
    }

    private func setStatus(_ text: String, for slot: AdSlot, color: UIColor) {
        guard let adContainer = adContainersByPadId[slot.padId], let statusLabel = statusLabelsByPadId[slot.padId] else {
            return
        }

        if statusLabel.superview == nil {
            adContainer.addSubview(statusLabel)
            NSLayoutConstraint.activate([
                statusLabel.topAnchor.constraint(equalTo: adContainer.topAnchor, constant: 12),
                statusLabel.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor, constant: 12),
                statusLabel.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor, constant: -12),
                statusLabel.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor, constant: -12)
            ])
        }

        statusLabel.text = text
        statusLabel.textColor = color
    }
}

// MARK: - InlineAdProviderLoadingDelegate

extension InLineViewController: InlineAdProviderLoadingDelegate {
    func inlineAdProvider(_ provider: InlineAdProvider, didReceive response: InlineAdProvider.Response, for slot: AdSlot) {
        // Обрабатываются сценарии успешной загрузки, ошибки и отсутствия контента.
        switch response {
        case .success:
            renderAd(for: slot)
        case let .failure(error, _):
            showError(error.localizedDescription, for: slot)
        case .noContent:
            showError("No inline ad content", for: slot)
        @unknown default:
            break
        }
    }
}

// MARK: - InlineAdProviderDelegate

extension InLineViewController: InlineAdProviderDelegate {
    func inlineAdProvider(_ provider: InlineAdProvider, didEmit event: InlineAd.Event, for slot: AdSlot) {
        // События отражают жизненный цикл конкретного inline-placement.
        switch event {
        case let .banner(event):
            print("Inline banner event for padId \(slot.padId): \(event)")
        case let .stories(event):
            print("Inline stories event for padId \(slot.padId): \(event)")
        @unknown default:
            break
        }
    }

    func inlineAdProvider(_ provider: InlineAdProvider, didEmit action: InlineAd.Action, for slot: AdSlot) {
        // Действия отражают пользовательские взаимодействия с рекламным placement.
        switch action {
        case let .onUrlClicked(_, _, url):
            print("Inline action URL clicked for padId \(slot.padId): \(url)")
        case let .onPromocodeCopy(_, promocode):
            print("Inline action promocode copied for padId \(slot.padId): \(promocode)")
        case let .onCustomAction(_, action, data):
            print("Inline custom action for padId \(slot.padId): \(action), data: \(data)")
        @unknown default:
            break
        }
    }
}
