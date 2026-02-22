
//
//  QRScanner.swift
//  encrypt
//
//  UIKit, iOS 12+, @objc selectors, component UIViews
//

import Airgap
import AVFoundation
import AudioToolbox
import Foundation
import UIKit

enum ScannerState: Equatable {
    case idle
    case scanning
    case processing
    case success(Data)
    case error(String)
}



final class IdleStateView: UIView {


    var onStart: (() -> Void)?

    private let iconView: UIImageView = {
        let iv          = UIImageView()
        iv.image        = UIImage(named: "icon_qr_scanner")
        iv.tintColor    = Palette.blue
        iv.contentMode  = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = .make(
        text: "QR Code Scanner",
        size: 22,
        weight: .semibold
    )

    private let subtitleLabel: UILabel = .make(
        text: "Position QR codes within the camera view",
        size: 15,
        color: Palette.gray
    )

    private let startButton = FilledButton(title: "Start Scanning", color: Palette.blue)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        startButton.onTap { [weak self] in self?.onStart?() }
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        iconView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel, startButton])
        stack.axis      = .vertical
        stack.spacing   = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}


final class ScanningStateView: UIView {

    var onCancel: (() -> Void)?

    // Waiting sub-panel
    private let waitingPanel: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .whiteLarge)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let waitLabel: UILabel = .make(
        text: "Waiting for QR code...",
        size: 16,
        color: Palette.gray
    )

    // Progress sub-panel
    private let progressPanel: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scanningLabel: UILabel = .make(
        text: "Scanning",
        size: 17,
        weight: .semibold,
        alignment: .left
    )

    private let countLabel: UILabel = {
        let l = UILabel.make(size: 15, color: Palette.gray, alignment: .right)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let progressView: UIProgressView = {
        let pv        = UIProgressView(progressViewStyle: .default)
        pv.tintColor  = Palette.blue
        pv.transform  = CGAffineTransform(scaleX: 1, y: 2)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let cancelButton = FilledButton(title: "Cancel", color: UIColor(white: 0.75, alpha: 1))

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        cancelButton.onTap { [weak self] in self?.onCancel?() }
        setupLayout()
        showWaiting()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Layout

    private func setupLayout() {
        // Waiting panel internals
        let waitStack = UIStackView(arrangedSubviews: [spinner, waitLabel])
        waitStack.axis      = .vertical
        waitStack.spacing   = 12
        waitStack.alignment = .center
        waitStack.translatesAutoresizingMaskIntoConstraints = false
        waitingPanel.addSubview(waitStack)
        pin(waitStack, to: waitingPanel)

        // Progress panel internals
        let headerRow = UIStackView(arrangedSubviews: [scanningLabel, countLabel])
        headerRow.axis         = .horizontal
        headerRow.distribution = .fill
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let progressStack = UIStackView(arrangedSubviews: [headerRow, progressView])
        progressStack.axis    = .vertical
        progressStack.spacing = 12
        progressStack.translatesAutoresizingMaskIntoConstraints = false
        progressPanel.addSubview(progressStack)
        pin(progressStack, to: progressPanel)

        // Outer
        let outer = UIStackView(arrangedSubviews: [waitingPanel, progressPanel, cancelButton])
        outer.axis      = .vertical
        outer.spacing   = 16
        outer.alignment = .fill
        outer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outer)
        pin(outer, to: self)
    }


    func update(scannedChunks: Set<Int>, totalChunks: Int, progress: Double) {
        if totalChunks > 0 {
            showProgress(scanned: scannedChunks, total: totalChunks, value: Float(progress))
        } else {
            showWaiting()
        }
    }

    private func showWaiting() {
        spinner.startAnimating()
        waitingPanel.isHidden  = false
        progressPanel.isHidden = true
    }

    private func showProgress(scanned: Set<Int>, total: Int, value: Float) {
        spinner.stopAnimating()
        waitingPanel.isHidden  = true
        progressPanel.isHidden = false
        countLabel.text        = "\(scanned.count) / \(total)"
        progressView.setProgress(value, animated: true)
    }
}


final class ProcessingStateView: UIView {

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .whiteLarge)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let titleLabel: UILabel    = .make(text: "Processing data...",      size: 17, weight: .semibold)
    private let subtitleLabel: UILabel = .make(text: "Decoding received chunks", size: 15, color: Palette.gray)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [spinner, titleLabel, subtitleLabel])
        stack.axis      = .vertical
        stack.spacing   = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        pin(stack, to: self)
        spinner.startAnimating()
    }
}

// MARK: SuccessStateView

final class SuccessStateView: UIView {

    var onUseData: (() -> Void)?
    var onScanAgain: (() -> Void)?

    private let iconView: UIImageView = {
        let iv         = UIImageView()
        iv.image       = UIImage(named: "icon_checkmark_circle")
        iv.tintColor   = Palette.green
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel    = .make(text: "Success!", size: 22, weight: .semibold)
    private let subtitleLabel: UILabel = .make(size: 15, color: Palette.gray)

    private let useDataButton   = FilledButton(title: "Use Data",    color: Palette.green)
    private let scanAgainButton = FilledButton(title: "Scan Again",  color: Palette.blue)

    init(byteCount: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Received \(byteCount) bytes"
        useDataButton.onTap   { [weak self] in self?.onUseData?() }
        scanAgainButton.onTap { [weak self] in self?.onScanAgain?() }
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        iconView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let buttonRow = UIStackView(arrangedSubviews: [useDataButton, scanAgainButton])
        buttonRow.axis         = .horizontal
        buttonRow.spacing      = 12
        buttonRow.distribution = .fillEqually
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel, buttonRow])
        stack.axis      = .vertical
        stack.spacing   = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        pin(stack, to: self)
    }
}


final class ErrorStateView: UIView {

    var onTryAgain: (() -> Void)?

    private let iconView: UIImageView = {
        let iv         = UIImageView()
        iv.image       = UIImage(named: "icon_warning")
        iv.tintColor   = Palette.red
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel   = .make(text: "Error", size: 22, weight: .semibold)
    private let messageLabel: UILabel = .make(size: 15, color: Palette.gray)
    private let tryAgainButton        = FilledButton(title: "Try Again", color: Palette.blue)

    init(message: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        tryAgainButton.onTap { [weak self] in self?.onTryAgain?() }
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        iconView.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel, tryAgainButton])
        stack.axis      = .vertical
        stack.spacing   = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        pin(stack, to: self)
    }
}

@MainActor private func pin(_ child: UIView, to parent: UIView) {
    NSLayoutConstraint.activate([
        child.topAnchor.constraint(equalTo: parent.topAnchor),
        child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
        child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    ])
}


public final class QRScannerViewController: UIViewController, @MainActor AVCaptureMetadataOutputObjectsDelegate {



    public var onDataReceived: ((Data) -> Void)?
    
    public var onClose: (() -> Void)!


    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let viewModel = QRScannerViewModel()

    private let overlayContainer: UIVisualEffectView = {
        let v              = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        v.layer.cornerRadius = 20
        v.clipsToBounds    = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var currentStateView: UIView?
    
    @objc func close() {
        self.onClose?()
    }
 
    public func setupCloseButton() {
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.close))
    }


    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()

        viewModel.addListener {
             [weak self] in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async { self.render(state: self.viewModel.state) }
        }

        render(state: viewModel.state)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        if let connection = previewLayer?.connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
        }
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
            switch UIApplication.shared.statusBarOrientation {
            case .portrait:           return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft:      return .landscapeLeft
            case .landscapeRight:     return .landscapeRight
            default:                  return .portrait
            }
        }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard
            let session = captureSession,
            let device  = AVCaptureDevice.default(for: .video),
            let input   = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        let meta = AVCaptureMetadataOutput()
        guard session.canAddOutput(meta) else { return }
        session.addOutput(meta)
        meta.setMetadataObjectsDelegate(self, queue: .main)
        meta.metadataObjectTypes = [.qr]

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill

        if let layer = previewLayer {
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, at: 0)
        }
    
    }

    @objc private func startCapture() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    @objc private func stopCapture() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }


    public func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let str = obj.stringValue
        else { return }

        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        viewModel.processQRCode(str)
    }


    private func setupOverlay() {
        view.addSubview(overlayContainer)
        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            overlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            overlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            overlayContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -pad)
        ])
    }

    private func swapStateView(to newView: UIView) {
        currentStateView?.removeFromSuperview()
        currentStateView = newView
        overlayContainer.contentView.addSubview(newView)

        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: overlayContainer.contentView.topAnchor, constant: pad),
            newView.leadingAnchor.constraint(equalTo: overlayContainer.contentView.leadingAnchor, constant: pad),
            newView.trailingAnchor.constraint(equalTo: overlayContainer.contentView.trailingAnchor, constant: -pad),
            newView.bottomAnchor.constraint(equalTo: overlayContainer.contentView.bottomAnchor, constant: -pad)
        ])
    }

    // MARK: - State Rendering

    private func render(state: ScannerState) {
        switch state {
        case .idle:               renderIdle()
        case .scanning:           renderScanning()
        case .processing:         renderProcessing()
        case .success(let data):  renderSuccess(data: data)
        case .error(let message): renderError(message: message)
        }
    }

    private func renderIdle() {
        stopCapture()
        let panel = IdleStateView()
        panel.onStart = { [weak self] in
            self?.viewModel.startScanning()
            self?.startCapture()
        }
        swapStateView(to: panel)
    }

    private func renderScanning() {
        if let existing = currentStateView as? ScanningStateView {
            existing.update(
                scannedChunks: viewModel.scannedChunks,
                totalChunks:   viewModel.totalChunks,
                progress:      viewModel.progress
            )
            return
        }

        let panel = ScanningStateView()
        panel.onCancel = { [weak self] in
            self?.stopCapture()
            self?.viewModel.reset()
        }
        panel.update(
            scannedChunks: viewModel.scannedChunks,
            totalChunks:   viewModel.totalChunks,
            progress:      viewModel.progress
        )
        swapStateView(to: panel)
    }

    private func renderProcessing() {
        swapStateView(to: ProcessingStateView())
    }

    private func renderSuccess(data: Data) {
        let panel = SuccessStateView(byteCount: data.count)
        panel.onUseData = { [weak self] in
            self?.onDataReceived?(data)
        }
        panel.onScanAgain = { [weak self] in
            self?.viewModel.reset()
            self?.startCapture()
        }
        swapStateView(to: panel)
    }

    private func renderError(message: String) {
        let panel = ErrorStateView(message: message)
        panel.onTryAgain = { [weak self] in
            self?.viewModel.reset()
            self?.startCapture()
        }
        swapStateView(to: panel)
    }
}
