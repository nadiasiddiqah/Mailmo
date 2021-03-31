//
//  New_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/30/21.
//

import UIKit
import Lottie
import Speech
import AVFoundation
import Accelerate
import WaveformView_iOS

class New_VC: UIViewController {
    
    // MARK: - Outlet Variables
    @IBOutlet weak var speechTextView: UITextView!
    @IBOutlet weak var dotsView: UIImageView!
    @IBOutlet weak var audioView: AudioVisualizerView!
    
    @IBOutlet weak var recordView: UIButton!
    @IBOutlet weak var speakButton: UIButton!
    @IBOutlet weak var tapToLabel: UILabel!
    
    // MARK: - Speech Variables
    var isButtonEnabled: Bool = false
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var renderTs: Double = 0
    private var recordingTs: Double = 0
    private var silenceTs: Double = 0
    
    
    // MARK: - Lottie Animation Variables
    lazy var dotsAnimation: AnimationView = {
        loadAnimation(fileName: "dotsAnimation", loadingView: dotsView)
    }()
    
    lazy var recordAnimation: AnimationView = {
        loadAnimation(fileName: "recordAnimation", loadingView: recordView)
    }()
    

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestPermission()
        setupAnimations()
        setupAudioView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dotsAnimation.pause()
        recordAnimation.pause()
    }
    
    // MARK: - Action Methods
    
    // Triggers speech recognizer to start or stop
    @IBAction func didTapToSpeak(_ sender: UIButton) {
        // Check if audio engine is running
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            
            speakButton.isEnabled = false
            recordAnimation.stop()
            audioView.isHidden = true
        } else {
            startSpeechRecognizer()
            tapToLabel.text = "Tap to finish"
            audioView.isHidden = false
            recordAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        }
    }
    
    // MARK: - Methods
    func setupAudioView() {
        audioView.isHidden = true
    }
    
    func setupAnimations() {
        dotsAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        recordAnimation.pause()
    }
    
    // Request speech recognition / microphone permissions
    func requestPermission() {
        speakButton.isEnabled = false
        speechRecognizer?.delegate = self
    
        // Requests + checks speech recognition authStatus
        SFSpeechRecognizer.requestAuthorization { [self] (authStatus) in
            var isButtonEnabled = false
    
            // Checks for authStatus
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            default:
                isButtonEnabled = false
            }
     
            // Enable speakButton based on authStatus
            OperationQueue.main.addOperation {
                self.speakButton.isEnabled = isButtonEnabled
                
                if isButtonEnabled == false {
                    handlePermissionFailed()
                }
            }
        }
    }
    
    func startSpeechRecognizer() {
        
        // Cancel any existing recognitionTask
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Set up audio session properties
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session Properties were not set because of an error")
            handleError(message: "Error in speech recognizer audio session.")
        }
        
        // Check speech recognizer availability
        guard let speechRecognizer = speechRecognizer else {
            self.handleError(message: "Speech recognition not available for specified locale.")
            return
        }
        
        // If speech recognizer is not currently available
        if !speechRecognizer.isAvailable {
            self.handleError(message: "Speech recognition not currently available.")
        }
        
        // Check if speech recognition request is created
        guard let recognitionRequest = recognitionRequest else {
            self.handleError(message: "Speech recognition request is unable to be created.")
            return
        }
        
        // Create inputNode and outputFormat for speech request
        let inputNode = audioEngine.inputNode
        let outputFormat = inputNode.outputFormat(forBus: 0)
        
        // Install audio tap to record, monitor, and observe output of inputNode
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
            
            let level: Float = -50
            let length: UInt32 = 1024
            buffer.frameLength = length
            let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
            var value: Float = 0
            vDSP_meamgv(channels[0], 1, &value, vDSP_Length(length))
            var average: Float = ((value == 0) ? -100 : 20.0 * log10f(value))
            if average > 0 {
                average = 0
            } else if average < -100 {
                average = -100
            }
            let silent = average < level
            let ts = NSDate().timeIntervalSince1970
            if ts - self.renderTs > 0.1 {
                let floats = UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength))
                let frame = floats.map({ (f) -> Int in
                    return Int(f * Float(Int16.max))
                })
                DispatchQueue.main.async {
                    self.renderTs = ts
                    let len = self.audioView.waveforms.count
                    for i in 0 ..< len {
                        let idx = ((frame.count - 1) * i) / len
                        let f: Float = sqrt(1.5 * abs(Float(frame[idx])) / Float(Int16.max))
                        self.audioView.waveforms[i] = min(49, Int(f * 50))
                    }
                    self.audioView.active = !silent
                    self.audioView.setNeedsDisplay()
                }
            }
        }
        
        // Check is audioEngine can start without throwing error
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            handleError(message: "Speech recognizer audio engine is unable to start.")
            print(error.localizedDescription)
        }
        
        // Initialize speechTextView after starting audioEngine
        speechTextView.text = "Say something, I'm listening!"
        
        // Set up speech recognizer task
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            self.dotsView.isHidden = true
            
            // If there is a speech result
            if result != nil {
                // Update speechTextView with bestTranscription result
                self.speechTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            // If there is an error / speech result is not final
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speakButton.isEnabled = true
            }
        })
    }

    func handleError(message: String) {
        let alert = UIAlertController(title: "Error has occurred",
                                      message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handlePermissionFailed() {
        let alert = UIAlertController(title: "Mailmo requires microphone and speech recognition permissions to work.",
                                      message: "Please update your settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { (_) in
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: "backToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension New_VC: SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        if available {
            speakButton.isEnabled = true
        } else {
            speakButton.isEnabled = false
            tapToLabel.text = "Speech recognition not available."
        }
    }
}
