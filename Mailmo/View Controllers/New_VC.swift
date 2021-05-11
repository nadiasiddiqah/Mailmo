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
    var isButtonEnabled: Bool = false
    var didStartRecognizer: Bool = false
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
        loadAnimation(fileName: "dotsAnimation", loadingView: dotsView)
    }()
    
    lazy var recordAnimation: AnimationView = {
        loadAnimation(fileName: "recordAnimation", loadingView: recordView)
    }()
    
//    lazy var nextButtonGif: GIFImageView = {
//        let gif = GIFImageView(frame: CGRect(x: speakButton.frame.origin.x, y: speakButton.frame.origin.y,
//                                             width: speakButton.frame.width, height: speakButton.frame.height))
//        gif.frame = speakButton.frame
//        gif.contentMode = .scaleAspectFit
//        gif.animate(withGIFNamed: "nextButton")
//
//        return gif
//    }()
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNewView()
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
            let controller = segue.destination as! New_Edit_VC
            controller.email.body = speechTextView.text
        } 
    }
    
    // MARK: - Action Methods
    
    // Triggers speech recognizer to start, retry, resume, or stop
    @IBAction func didTapSpeechOrNextButton(_ sender: UIButton) {
        if !audioEngine.isRunning && speechOrNextButton.currentImage == nil &&
            !didPressPause && speechTextView.text != noVoice {
            // Tap to start
            print("tap to start")
            
            // Start speech recognizer
            showTapToFinish(showDots: true, isPaused: false)
            
            // Stop timer after 5s if no voice detected
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [self] in
                if speechTextView.text == introText {
                    print("voice not detected after 5s")
                    voiceNotDetected()
                }
            }
        } else if audioEngine.isRunning && speechTextView.text != noVoice
                    && didPressPause {
            // Tap to stop (if paused)
            print("tap to finish")
            determineNextStep()
        } else if speechTextView.text == noVoice || didPressPause {
            // Tap to retry/resume
            if didPressPause {
                print("tap to resume")
            } else {
                print("tap to retry")
            }
            
            // Start speech recognizer
            showTapToFinish(showDots: !didPressPause, isPaused: didPressPause)

            // Stop timer after 5s if no voice detected
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [self] in
                if speechTextView.text == introText {
                    voiceNotDetected()
                }
            }
        } else {
            // Tap to finish
            print("tap to finish")
            determineNextStep()
        }
    }
    
    @IBAction func restartButton(_ sender: Any) {
        print("tap to restart")
        speechOrNextButton.isEnabled = false
        resetNewView()
    }

    @IBAction func pauseButton(_ sender: Any) {
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
    func setupNewView() {
        // Check for permissions
        requestPermission()
        
        // Initialize textView, savedText, timeLeft
        speechTextView.fadeTransition(0.6)
        speechTextView.text = "↓Tap the button below to start recording and transcribing your email..."
        savedText = ""
        timeLeft = 10
        
        // Disable record animation
        recordAnimation.isHidden = false
        recordAnimation.stop()
        
        // Initialize buttons + bools
        restartButton.isEnabled = false
        pauseButton.isEnabled = false
        didPressPause = false
        
        // Intialize speechButton + tapToLabel text
        speechOrNextButton.isEnabled = true
        speechOrNextButton.setImage(nil, for: .normal)
        tapToLabel.text = "Tap to start"
    }
    
    func resetNewView() {
        checkOrStopSpeechRecognizer()
        
        // Restart new view + timer
        setupNewView()
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
            print("unsuccessful speech-to-text")
        } else {
            // If tapped + speech-to-text is successful -> show nextButton
            recordAnimation.isHidden = true
//            speakButton.addSubview(nextButtonGif)
            speechOrNextButton.setImage(UIImage(named: "next_button"), for: .normal)
            tapToLabel.text = "Next Step"
            print("successful speech-to-text")
        }
    }
  
    // MARK: - Speech Recognizer Permission Methods
    
    // Request speech recognition / microphone permissions
    func requestPermission() {
        speechOrNextButton.isEnabled = false
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
                self.speechOrNextButton.isEnabled = isButtonEnabled
                
                if isButtonEnabled == false {
                    handlePermissionFailed()
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
        print("start speech recognizer")
        
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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
            
            // Configure audioView based on audio tap
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
        
        // Set up speech recognizer task
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { [self] (result, error) in
            
            dotsAnimation.isHidden = true
            pauseButton.isEnabled = true
            
            // Check if there is results
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                
                if didPressPause {
                    // Pressed pause button
                    if !bestString.contains("I") {
                        speechTextView.text = savedText + " " + bestString.lowercased()
                    }
                } else {
                    // Pressed tap to finish button
                    speechTextView.text = bestString
                }
            }
    
            // Check if there is non-nil error
            if error != nil {
                
                if recognitionTask != nil || didPressPause {
                    // Update savedText (for pauses)
                    savedText = speechTextView.text
                    
                    if !didPressPause {
                        stopSpeechRecognizer()
                    }
                }
                
                // Remove audio tap + enable speechOrNextButton
                inputNode.removeTap(onBus: 0)
                speechOrNextButton.isEnabled = true
                
                print("speechTextView: \(speechTextView.text ?? "no text")")
                print("savedText: \(savedText)")
            
            }
        })
    }
    
    // Stop speech recognizer (unless stopped already)
    func checkOrStopSpeechRecognizer() {
        if recognitionTask != nil {
            stopSpeechRecognizer()
        }
    }
    
    func stopSpeechRecognizer() {
        // Stop audio for speech recognizer
        print("stop speech recognizer")
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: "backToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }

}
