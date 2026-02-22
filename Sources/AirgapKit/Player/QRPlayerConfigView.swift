//
//  QRPlayerConfigView.swift
//  AirgapKit
//
//  Created by Alex M on 18.02.2026.
//
import UIKit

@available(iOS 13.0, *)
final class QRPlayerConfigView: UIView {
    var onChunkChanged: ((Double) -> Void)?

    private let chunkValueLabel = UILabel()
    private let chunkSlider = UISlider()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let stack = UIStackView(arrangedSubviews: [chunkValueLabel, chunkSlider])
        stack.spacing = 8
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        chunkValueLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        chunkValueLabel.textColor = .secondaryLabel
        chunkValueLabel.textAlignment = .center
        
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        chunkSlider.heightAnchor.constraint(equalToConstant: 57.5).isActive = true

        chunkSlider.minimumValue = 16
        chunkSlider.maximumValue = 1920
        chunkSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        updateLabel(460)
    }

    func setChunkSize(_ value: Double) {
        chunkSlider.value = Float(value)
        updateLabel(value)
    }

    func setEnabled(_ enabled: Bool) {
        chunkSlider.isEnabled = enabled
        chunkValueLabel.alpha = enabled ? 1.0 : 0.5
    }

    private func updateLabel(_ value: Double) {
        chunkValueLabel.text = "Chunk size: \(Int(value)) bytes"
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        let value = Double(sender.value)
        updateLabel(value)
        onChunkChanged?(value)
    }
}
