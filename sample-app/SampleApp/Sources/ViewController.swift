import UIKit

public class ViewController: UIViewController {
    private let inAppButton = UIButton(type: .system)
    private let inLineButton = UIButton(type: .system)
    private let stackView = UIStackView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "MadSDK Sample"

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
        inAppButton.setTitle("InApp", for: .normal)
        inAppButton.addTarget(self, action: #selector(didTapInApp), for: .touchUpInside)

        inLineButton.setTitle("InLine", for: .normal)
        inLineButton.addTarget(self, action: #selector(didTapInLine), for: .touchUpInside)

        stackView.addArrangedSubview(inAppButton)
        stackView.addArrangedSubview(inLineButton)

        [inAppButton, inLineButton].forEach { button in
            button.backgroundColor = .red
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
            button.clipsToBounds = true
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }

    @objc
    private func didTapInApp() {
        let vc = InAppViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc
    private func didTapInLine() {
        let vc = InLineViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
