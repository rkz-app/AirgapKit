//
//  QrPlayerController.swift
//  AirgapKit
//
//  Created by Alex M on 17.02.2026.
//

import UIKit



@available(iOS 13.0, *)
public final class QRPlayerViewController: UIViewController {

    // MARK: - ViewModel

    private let viewModel: QRPlayerViewModel
    
    public var onClose: (() -> Void)!
    
    // MARK: - UI

    private let displayView = QRPlayerDisplayView()

    private let configView = QRPlayerConfigView()
    private let buildButton = UIButton(type: .system)
    
    private var controlsView: QRPlayerControlsView = QRPlayerControlsView()

    // MARK: - Playback

    private var playbackTimer: Timer?
    
    private var frameRate: Float = 2.0
    
    private var selectedChunkSize: Double = 460

    // MARK: - Init

    public init(data: Data, title: String) {
        self.viewModel = QRPlayerViewModel(data: data)
        
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.viewModel.addListener { [weak self] in
            DispatchQueue.main.async {
                self?.viewModelChanged()
            }
        }
    }
    
    func viewModelChanged() {
        switch self.viewModel.state {
        case .playing:
            startPlayback()
        case .pause:
            stopPlayback()
        default:
            stopPlayback()
        }
        self.updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        updateUI()
    }
    
    @objc func close() {
        self.onClose?()
    }
 
    public func setupCloseButton() {
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.close))
    }
    // MARK: - Setup

    private func setupUI() {
        
        controlsView.setSpeed(2.0)
        
        controlsView.onBackButtonTapped = {[weak self] in
            
            guard let viewModel = self?.viewModel  else {
                return
            }
            
            viewModel.backward()
        }
        
        controlsView.onForwardButtonTapped = {[weak self] in
            
            guard let viewModel = self?.viewModel  else {
                return
            }
            viewModel.forward()
        }
        
        controlsView.onPlayButtonTapped = {[weak self] in
            
            guard let viewModel = self?.viewModel  else {
                return
            }
            
            viewModel.state == .playing ? viewModel.pause() : viewModel.play()
        }
        
        controlsView.onSpeedChanged = {[weak self]speed in
            self?.frameRate = speed
        }
       
        configView.setChunkSize(selectedChunkSize)
        configView.onChunkChanged = { [weak self] newValue in
            self?.selectedChunkSize = newValue
        }

        buildButton.setTitle("Build QR Codes", for: .normal)
        buildButton.addTarget(self, action: #selector(buildTapped), for: .touchUpInside)

        layoutUI()
    }
    
    private func layoutUI() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])

        displayView.translatesAutoresizingMaskIntoConstraints = false
        displayView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
    
        mainStack.addArrangedSubview(displayView)
        mainStack.addArrangedSubview(configView)
        mainStack.addArrangedSubview(controlsView)
        mainStack.addArrangedSubview(buildButton)

        controlsView.isHidden = true
    }


    // MARK: - UI Updates

    private func updateUI() {
        
        switch viewModel.state {
        case .initial:
            controlsView.isHidden = true
            configView.isHidden = false
            configView.setEnabled(true)
            buildButton.setTitle("Build QR Codes", for: .normal)
            buildButton.isEnabled = true
            showMessage("Configure settings and build QR codes")
        case .buildingQR:
            controlsView.isHidden = true
            configView.isHidden = false
            configView.setEnabled(false)
            buildButton.setTitle("Building...", for: .normal)
            buildButton.isEnabled = false
            showLoading("Generating QR codes...")
        case .qrError(let error):
            controlsView.isHidden = true
            configView.isHidden = false
            configView.setEnabled(true)
            buildButton.isEnabled = true
            buildButton.setTitle("Build QR Codes", for: .normal)
            showMessage("Error:\n\(error)")
        case .pause, .playing:
            controlsView.isHidden = false
            controlsView.setSliderEnabled(viewModel.state == .pause)
            configView.isHidden = true
            buildButton.isEnabled = true
            buildButton.setTitle("Rebuild", for: .normal)
            showImage()
            controlsView.setFrameLabelText(index: viewModel.currentIndex, total: viewModel.images.count)
            updateControlsView()
        }
    }

    private func showMessage(_ text: String) {
        displayView.showMessage(text)
    }

    private func showLoading(_ text: String) {
        displayView.showLoading(text)
    }

    private func showImage() {
        if !viewModel.images.isEmpty {
            displayView.showImage(viewModel.images[viewModel.currentIndex])
        } else {
            displayView.showMessage("")
        }
    }

  
    
    private func updateControlsView() {
        controlsView.setPlayButtonImage(state: viewModel.playButtonState)
        controlsView.setBackButtonEnabled(!viewModel.isPlaying && viewModel.currentIndex > 0)
        controlsView.setForwardButtonEnabled(!viewModel.isPlaying &&
            viewModel.currentIndex < viewModel.images.count - 1)
    }

    // MARK: - State Handling


    private func startPlayback() {
        stopPlayback()

        let interval = 1.0 / frameRate
        playbackTimer = Timer.scheduledTimer(withTimeInterval: Double(interval), repeats: true) { [weak self] _ in
            self?.viewModel.nextFrame()
            self?.updateUI()
        }
    }

    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - Actions

    @objc private func buildTapped() {
        if [ViewModelState.pause, ViewModelState.pause].contains(viewModel.state) {
            viewModel.state = .initial
            viewModel.currentIndex = 0
            return
        }
        Task {
            viewModel.chunkSize = UInt(selectedChunkSize)
            await viewModel.assemble()
        }
    }
    
}
