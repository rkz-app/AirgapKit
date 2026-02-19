//
//  QRPlayerDisplayView.swift
//  AirgapKit
//
//  Created by Alex M on 18.02.2026.
//

import UIKit

@available(iOS 13.0, *)
final class QRPlayerDisplayView: UIView {
    private let container = UIView()
    private let imageView = UIImageView()
    private let messageLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .secondaryLabel
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        container.addSubview(imageView)
        container.addSubview(messageLabel)
        container.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -10),

            messageLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -10),

            activityIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        showMessage("Configure settings and build QR codes")
    }

    // MARK: - Public API

    func showMessage(_ text: String) {
        imageView.isHidden = true
        activityIndicator.stopAnimating()
        messageLabel.isHidden = false
        messageLabel.text = text
    }

    func showLoading(_ text: String) {
        imageView.isHidden = true
        messageLabel.isHidden = false
        messageLabel.text = text
        activityIndicator.startAnimating()
    }

    func showImage(_ image: UIImage?) {
        messageLabel.isHidden = true
        activityIndicator.stopAnimating()
        imageView.isHidden = false
        imageView.image = image
    }
}
