//
//  ControlsView.swift
//  AirgapKit
//
//  Created by Alex M on 18.02.2026.
//
import UIKit


enum PlayButtonState {
    case play
    case pause
    case replay
}


extension PlayButtonState {
    var imageName: String {
        switch self {
        case .pause:
            return "pause.circle.fill"
        case .play:
            return "play.circle.fill"
        case .replay:
            return "arrow.counterclockwise.circle.fill"
        }
    }
}

@available(iOS 13.0, *)
final class QRPlayerControlsView: UIView {

    var onBackButtonTapped: VoidCallback?
    var onPlayButtonTapped: VoidCallback?
    var onForwardButtonTapped: VoidCallback?
    
    private let frameLabel = UILabel()
    
    var onSpeedChanged: ((Float) -> Void)?
    
    private let backButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    
    private let speedSlider = UISlider()
    private let speedValueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setSliderEnabled(_ value: Bool) {
        self.speedSlider.isEnabled = value
    }
    
    
    func setBackButtonEnabled(_ enabled: Bool) {
        self.backButton.isEnabled = enabled
    }
    
    func setForwardButtonEnabled(_ enabled: Bool) {
        self.forwardButton.isEnabled = enabled
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setSpeed(_ value: Float) {
        self.speedSlider.value = value
        setSpeedLabel(value)
    }
    
    func setPlayButtonImage(state: PlayButtonState) {
        playPauseButton.setImage(UIImage(systemName: state.imageName), for: .normal)
    }

    func setFrameLabelText(index: Int, total: Int) {
        frameLabel.text = "Frame \(index + 1) / \(total)"
    }
    
    private func setup() {
        // Buttons row
        backButton.setImage(UIImage(systemName: "backward.frame.fill"), for: .normal)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.setImage(UIImage(systemName: "forward.frame.fill"), for: .normal)
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        
        setPlayButtonImage(state: .play)
        
        [backButton, playPauseButton, forwardButton].forEach { btn in
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 50).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        let buttonsRow = UIStackView(arrangedSubviews: [backButton, playPauseButton, forwardButton])
        buttonsRow.axis = .horizontal
        
        // Frame label configuration
        frameLabel.textAlignment = .center
        frameLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        frameLabel.textColor = .secondaryLabel
        frameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        speedValueLabel.textAlignment = .right
        speedValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        speedSlider.minimumValue = 1
        speedSlider.maximumValue = 4
    
        speedSlider.addTarget(self, action: #selector(speedChanged(_:)), for: .valueChanged)

        speedValueLabel.translatesAutoresizingMaskIntoConstraints = false
        speedValueLabel.text = ""
        
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        
        let speedRow = UIStackView(arrangedSubviews: [speedSlider, speedValueLabel])
        speedRow.axis = .horizontal
        speedRow.spacing = 16
        speedRow.alignment = .center
        
        // Adjust buttons row distribution for compact fit
        buttonsRow.spacing = 16
        buttonsRow.distribution = .fillProportionally
        buttonsRow.alignment = .center

      
        speedValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        speedValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Make slider flexible
        speedSlider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        speedSlider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Horizontal controls row (buttons left, speed right)
        let horizontalControls = UIStackView(arrangedSubviews: [buttonsRow, speedRow])
        horizontalControls.axis = .horizontal
        horizontalControls.spacing = 24
        horizontalControls.alignment = .center
        horizontalControls.distribution = .fill
        horizontalControls.translatesAutoresizingMaskIntoConstraints = false
        
      
        // Root vertical: frame label on top, controls below
        let root = UIStackView(arrangedSubviews: [frameLabel, horizontalControls])
        root.axis = .vertical
        root.spacing = 8
        root.alignment = .fill
        root.distribution = .fill
        root.translatesAutoresizingMaskIntoConstraints = false

        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Let the controls row hug its content and the speed row expand
        buttonsRow.setContentHuggingPriority(.required, for: .horizontal)
        buttonsRow.setContentCompressionResistancePriority(.required, for: .horizontal)
        speedRow.setContentHuggingPriority(.defaultLow, for: .horizontal)
        speedRow.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    @objc func speedChanged(_ sender: UISlider) {
        let step: Float = 0.5
        let minValue: Float = 1.0

        let stepped: Float = round((sender.value - minValue) / step) * step + minValue
        sender.value = stepped
        setSpeedLabel(stepped)
        onSpeedChanged?(stepped)
    }
    
    @objc private func playPauseTapped() {
        onPlayButtonTapped?()
    }

    @objc private func backTapped() {
        onBackButtonTapped?()
    }

    @objc private func forwardTapped() {
        onForwardButtonTapped?()
    }
    
    func setSpeedLabel(_ speed: Float) {
        speedValueLabel.text = "\(speed) fps"
    }
}

