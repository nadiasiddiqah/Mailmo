//
//  New_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/30/21.
//

import UIKit
import Lottie
import Gifu
import TinyConstraints
import Speech
import AVFoundation
import Accelerate

class New_VC: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: - Outlet Variables
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var speechTextView: UITextView!
    @IBOutlet weak var dotsView: UIImageView!
    @IBOutlet weak var audioView: AudioVisualizerView!
    
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var recordView: UIImageView!
    @IBOutlet weak var speechOrNextButton: UIButton!
    @IBOutlet weak var tapToLabel: UILabel!
    
    // MARK: - Speech Variables
    var didPressPause: Bool = false
    
    var timer: Timer?
    var timeLeft: Int = 10
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var savedText = String()
    let noVoice = "Voice not detected, try again..."
    let introText = "Say something, I'm listening!"
    
    private var renderTs: Double = 0
    private var recordingTs: Double = 0
    private var silenceTs: Double = 0
    
    // MARK: - Lottie Animation Variables
    lazy var dotsAnimation: AnimationView = {
        Utils.loadAnimation(fileName: "dotsAnimation", loadingView: dotsView)
    }()
    
    lazy var recordAnimation: AnimationView = {
        Utils.loadAnimation(fileName: "recordAnimation", loadingView: recordView)
    }()
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        checkOrStopSpeechRecognizer()
    }
    
    // MARK: - Navigation Methods
    @IBAction func unwindToMain(_ sender: Any) {
    }
    
    @IBAction func backToMain(_ sender: Any) {
        resetNewView()
        performSegue(withIdentifier: "unwindFromNewToMain", sender: nil)
    }
    
    @IBAction func unwindFromEditToNew(_ unwindSegue: UIStoryboardSegue) {
        resetNewView()
    }
    
    @IBAction func unwindFromHistoryToNew(_ unwindSegue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewEdit" {
            let controller = segue.destination as! Edit_VC
            controller.emailContent.body = speechTextView.text
        } else if segue.identifier == "unwindFromNewToMain" {
            let controller = segue.destination as! Main_VC
            controller.showPulsingButton = false
        }
    }
    
    // MARK: - Action Methods
    
    // Triggers speech recognizer to start, retry, resume, or stop
    @IBAction func didTapSpeechOrNextButton(_ sender: UIButton) {
        if !audioEngine.isRunning && speechOrNextButton.currentImage == nil &&
            !didPressPause && speechTextView.text != noVoice {
            // Tap to start speech recognizer
            showTapToFinish(showDots: true, isPaused: false)
            
            // Stop timer after 5s if no voice detected
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.speechTextView.text == self.introText {
                    self.voiceNotDetected()
                }
            }
        } else if audioEngine.isRunning && speechTextView.text != noVoice
                    && didPressPause {
            // Tap to finish or stop (if paused)
            determineNextStep()
        } else if speechTextView.text == noVoice || didPressPause {
            // Tap to retry or resume
            
            // Start speech recognizer
            showTapToFinish(showDots: !didPressPause, isPaused: didPressPause)

            // Stop timer after 5s if no voice detected
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.speechTextView.text == self.introText {
                    self.voiceNotDetected()
                }
            }
        } else {
            // Tap to finish
            determineNextStep()
        }
        
        if speechOrNextButton.currentImage == nil {
            recordAnimation.isHidden = false
        } else {
            recordAnimation.isHidden = true
        }
        
    }
    
    // Tap to restart
    @IBAction func pressedRestart(_ sender: Any) {
        speechOrNextButton.isEnabled = false
        resetNewView()
    }
    
    // Tap to pause
    @IBAction func pressedPause(_ sender: Any) {
        checkOrStopSpeechRecognizer()
        
        // Pause speechTimer
        stopTimer(message: "You have \(timeLeft)s left!", fadeTransition: false)
        
        // Enable controls
        restartButton.isEnabled = true
        pauseButton.isEnabled = false
        
        // Update tapToLabel
        tapToLabel.text = "Tap to resume"
        
        didPressPause = true
    }
    
    // MARK: - General Methods
    func setupView() {
        // Check for permissions
        requestPermissions()
        
        // Initialize textView, savedText, timeLeft
        speechTextView.fadeTransition(0.6)
        speechTextView.text = "↓Tap button below to start recording your email"
        savedText = ""
        timeLeft = 10
        
        // Disable record animation
        audioView.isHidden = true
        recordAnimation.isHidden = false
        recordAnimation.stop()
        
        // Initialize buttons + bools
        restartButton.isEnabled = false
        pauseButton.isEnabled = false
        didPressPause = false
        
        // Intialize speechButton + tapToLabel text
        speechOrNextButton.setImage(nil, for: .normal)
        tapToLabel.text = "Tap to start"
    }
    
    func resetNewView() {
        checkOrStopSpeechRecognizer()
        
        // Restart new view + timer
        setupView()
        stopTimer(message: "You have \(timeLeft)s left!", fadeTransition: true)
    }
    
    // MARK: - DidTapSpeechOrNextButton Methods
    
    // Starts speech recognizer
    func showTapToFinish(showDots: Bool, isPaused: Bool) {
        
        startSpeechRecognizer()
        
        // Enable controls
        tapToLabel.text = "Tap to finish"
        restartButton.isEnabled = true
        
        // Update speechTextView
        if isPaused {
            speechTextView.text = savedText
        } else {
            speechTextView.fadeTransition(0.6)
            speechTextView.text = introText
            dotsAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
            timeLeft = 10
            timerLabel.text = "You have \(timeLeft)s left!"
        }
        recordAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        startTimer()
    }
    
    // Stops speech recognizer if no voice is detected
    func voiceNotDetected() {
        // Stop speech recognizer + timer
        checkOrStopSpeechRecognizer()
        stopTimer(message: "", fadeTransition: true)
        
        // Update speechTextView + sppechOrNextButton
        speechTextView.fadeTransition(0.6)
        speechTextView.text = noVoice
        speechOrNextButton.setImage(nil, for: .normal)
        
        // Update recordAnimation
        recordAnimation.isHidden = false
        recordAnimation.stop()
        
        // Update tapToLabel
        tapToLabel.fadeTransition(0.6)
        tapToLabel.text = "Tap to start"
    }
    
    // Determines whether to segue, show next button, or restart
    func determineNextStep() {
        checkOrStopSpeechRecognizer()
        
        if speechOrNextButton.currentImage != nil {
            // If tapped + nextButton is shown -> segue to New_Edit
            performSegue(withIdentifier: "showNewEdit", sender: nil)
        } else if speechTextView.text == introText || speechTextView.text == noVoice {
            // If tapped + no speech-to-text -> retry
            voiceNotDetected()
        } else {
            // If tapped + speech-to-text is successful -> show nextButton
            speechOrNextButton.setImage(UIImage(named: "next_button"), for: .normal)
            tapToLabel.text = "Next Step"
        }
    }
  
    // MARK: - Speech Recognizer Permission Methods
    
    // Request speech recognition / microphone permissions
    func requestPermissions() {
        speechOrNextButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        var isSpeechEnabled = false
        var isMicEnabled = false
        
        // Requests speech recognition / microphone permissions
        SFSpeechRecognizer.requestAuthorization { [weak self] (authStatus) in
            
            guard let strongSelf = self else { return }
    
            // Checks for speech recognition authStatus
            switch authStatus {
            case .authorized:
                isSpeechEnabled = true
            default:
                isSpeechEnabled = false
            }

            // Requests + checks microphone authStatus
            AVAudioSession.sharedInstance().requestRecordPermission { (authStatus) in
                switch authStatus {
                case true:
                    isMicEnabled = true
                case false:
                    isMicEnabled = false
                }
                
                // Enable speakButton based on authStatus
                OperationQueue.main.addOperation {
                    if isSpeechEnabled && isMicEnabled {
                        strongSelf.speechOrNextButton.isEnabled = true
                    } else {
                        strongSelf.speechOrNextButton.isEnabled = false
                    }
                    
                    if isSpeechEnabled == false {
                        strongSelf.handlePermissionFailed()
                    }
                }
            }
        }
    
    }
    
    // Check speech recognizer availability
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        if available {
            speechOrNextButton.isEnabled = true
        } else {
            speechOrNextButton.isEnabled = false
            tapToLabel.text = "Speech recognition not available."
        }
    }
    
    // MARK: - Timer Methods
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                     selector: #selector(updateTimer),
                                     userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        if timeLeft > 1 {
            timeLeft -= 1
            timerLabel.text = "You have \(timeLeft)s left!"
        } else if recognitionTask == nil {
            stopTimer(message: "You have \(timeLeft)s left!", fadeTransition: true)
        } else {
            stopTimer(message: "Time's up!", fadeTransition: true)
            determineNextStep()
        }
    }
    
    func stopTimer(message: String, fadeTransition: Bool) {
        if let timer = timer {
            timer.invalidate()
            if fadeTransition {
                timerLabel.fadeTransition(0.6)
            }
            timerLabel.text = message
        }
    }
    
    // MARK: - Speech Recognizer Methods
    
    func startSpeechRecognizer() {
        
        // Create new speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
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
        
        // Set up audio session properties
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            handleError(message: "Error in speech recognizer audio session.")
        }
        
        // Create inputNode and outputFormat for speech request
        let inputNode = audioEngine.inputNode
        let outputFormat = inputNode.outputFormat(forBus: 0)
        
        // Install audio tap to record, monitor, and observe output of inputNode
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { [weak self] (buffer, _) in
            
            guard let strongSelf = self else { return }
            
            strongSelf.recognitionRequest?.append(buffer)
            
            // Configure audioView based on audio tap
            let level: Float = -50
            let length: UInt32 = 1024
            buffer.frameLength = length
            
            let channels = UnsafeBufferPointer(start: buffer.floatChannelData,
                                               count: Int(buffer.format.channelCount))
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
            
            if ts - strongSelf.renderTs > 0.1 {
                let floats = UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength))
                let frame = floats.map({ (f) -> Int in
                    return Int(f * Float(Int16.max))
                })
                DispatchQueue.main.async {
                    strongSelf.renderTs = ts
                    let len = strongSelf.audioView.waveforms.count
                    for i in 0 ..< len {
                        let idx = ((frame.count - 1) * i) / len
                        let f: Float = sqrt(1.5 * abs(Float(frame[idx])) / Float(Int16.max))
                        strongSelf.audioView.waveforms[i] = min(49, Int(f * 50))
                    }
                    strongSelf.audioView.active = !silent
                    strongSelf.audioView.setNeedsDisplay()
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
        
        // Set up speech recognizer task
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
            
            guard let strongSelf = self else { return }

            strongSelf.audioView.isHidden = false
            strongSelf.dotsAnimation.isHidden = true

            // Check if there is results
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                
                strongSelf.pauseButton.isEnabled = true

                if strongSelf.didPressPause {
                    // Pressed pause button
                    if !bestString.contains("I") {
                        strongSelf.speechTextView.text = strongSelf.savedText + " " + bestString.lowercased()
                    }
                } else {
                    // Pressed tap to finish button
                    strongSelf.speechTextView.text = bestString
                }
            }

            // Check if there is non-nil error
            if error != nil {

                if strongSelf.recognitionTask != nil || strongSelf.didPressPause {
                    // Update savedText (for pauses)
                    strongSelf.savedText = strongSelf.speechTextView.text

                    if !strongSelf.didPressPause {
                        strongSelf.stopSpeechRecognizer()
                    }
                }

                // Remove audio tap + enable speechOrNextButton
                inputNode.removeTap(onBus: 0)
                strongSelf.speechOrNextButton.isEnabled = true
            }
        })
    }
        
    // Stop speech recognizer (unless stopped already)
    func checkOrStopSpeechRecognizer() {
        if recognitionTask != nil {
            stopSpeechRecognizer()
        }
    }
    
    // Stop audio for speech recognizer
    func stopSpeechRecognizer() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        // Cancel speech recognizer request and task
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        // Disable timer, record animation, pause button
        timer?.invalidate()
        recordAnimation.stop()
        pauseButton.isEnabled = false
    }

    // MARK: - Error Handling Methods
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.performSegue(withIdentifier: "unwindFromNewToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }

}
