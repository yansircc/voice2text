import Cocoa

class PreferencesWindowController: NSWindowController {
    
    private var apiKeyTextField: EditableNSSecureTextField!
    private var baseURLTextField: EditableNSTextField!
    private var modelPopUpButton: NSPopUpButton!
    private var languagePopUpButton: NSPopUpButton!
    private var temperatureSlider: NSSlider!
    private var temperatureLabel: NSTextField!
    private var promptTextView: NSTextView!
    
    private let userDefaults = UserDefaults.standard
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        
        window.title = "Voice2Text Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        
        createUI()
        loadSettings()
    }
    
    private func createUI() {
        guard let window = self.window else { return }
        let contentView = NSView()
        window.contentView = contentView
        
        // Title
        let titleLabel = NSTextField(labelWithString: "Voice2Text Preferences")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        
        // API Key section - using custom secure text field with paste support
        let apiKeyLabel = NSTextField(labelWithString: "API Key:")
        apiKeyTextField = EditableNSSecureTextField()
        apiKeyTextField.placeholderString = "Enter your Whisper API key"
        apiKeyTextField.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        
        // Base URL section
        let baseURLLabel = NSTextField(labelWithString: "API Base URL:")
        baseURLTextField = EditableNSTextField()
        baseURLTextField.placeholderString = "https://api.openai.com"
        
        // Model section
        let modelLabel = NSTextField(labelWithString: "Model:")
        modelPopUpButton = NSPopUpButton()
        modelPopUpButton.addItems(withTitles: [
            "whisper-large-v3 (Best for Chinese)",
            "whisper-1 (Stable & Reliable)",
            "distil-whisper-large-v3-en (Fast, English only)"
        ])
        
        // Language section
        let languageLabel = NSTextField(labelWithString: "Language:")
        languagePopUpButton = NSPopUpButton()
        languagePopUpButton.addItems(withTitles: [
            "Auto Detect",
            "Chinese (zh)",
            "English (en)",
            "Spanish (es)",
            "French (fr)",
            "German (de)",
            "Japanese (ja)",
            "Korean (ko)"
        ])
        
        // Temperature section
        let tempLabel = NSTextField(labelWithString: "Temperature:")
        temperatureSlider = NSSlider()
        temperatureSlider.minValue = 0.0
        temperatureSlider.maxValue = 1.0
        temperatureSlider.doubleValue = 0.2
        temperatureSlider.target = self
        temperatureSlider.action = #selector(temperatureChanged(_:))
        
        temperatureLabel = NSTextField(labelWithString: "0.2")
        temperatureLabel.isEditable = false
        temperatureLabel.isBordered = false
        temperatureLabel.backgroundColor = .clear
        
        let tempHintLabel = NSTextField(labelWithString: "Lower values reduce hallucinations")
        tempHintLabel.font = NSFont.systemFont(ofSize: 11)
        tempHintLabel.textColor = .secondaryLabelColor
        
        // Prompt section
        let promptLabel = NSTextField(labelWithString: "Context Prompt (Optional):")
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = false
        
        // Create text view with frame
        let textViewFrame = NSRect(x: 0, y: 0, width: 440, height: 60)
        promptTextView = NSTextView(frame: textViewFrame)
        promptTextView.isRichText = false
        promptTextView.font = NSFont.systemFont(ofSize: 12)
        promptTextView.isAutomaticQuoteSubstitutionEnabled = false
        promptTextView.isEditable = true
        promptTextView.isSelectable = true
        promptTextView.allowsUndo = true
        promptTextView.importsGraphics = false
        promptTextView.backgroundColor = NSColor.textBackgroundColor
        promptTextView.textColor = NSColor.labelColor
        promptTextView.isVerticallyResizable = true
        promptTextView.isHorizontallyResizable = false
        promptTextView.minSize = CGSize(width: 0, height: scrollView.contentSize.height)
        promptTextView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        promptTextView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        promptTextView.textContainer?.widthTracksTextView = true
        promptTextView.delegate = self
        
        scrollView.documentView = promptTextView
        
        let promptHintLabel = NSTextField(labelWithString: "e.g., \"This is a technical discussion about AI and machine learning.\"")
        promptHintLabel.font = NSFont.systemFont(ofSize: 11)
        promptHintLabel.textColor = .secondaryLabelColor
        
        // Buttons
        let buttonContainer = NSView()
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"  // Enter key
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelSettings(_:)))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"  // Escape key
        
        // Add all views
        let allViews: [NSView] = [
            titleLabel, apiKeyLabel, apiKeyTextField, baseURLLabel, baseURLTextField,
            modelLabel, modelPopUpButton, languageLabel, languagePopUpButton,
            tempLabel, temperatureSlider, temperatureLabel, tempHintLabel,
            promptLabel, scrollView, promptHintLabel, buttonContainer
        ]
        
        allViews.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
        
        [saveButton, cancelButton].forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            buttonContainer.addSubview(button)
        }
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // API Key
            apiKeyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            apiKeyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            apiKeyTextField.topAnchor.constraint(equalTo: apiKeyLabel.bottomAnchor, constant: 5),
            apiKeyTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            apiKeyTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Base URL
            baseURLLabel.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 15),
            baseURLLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            baseURLTextField.topAnchor.constraint(equalTo: baseURLLabel.bottomAnchor, constant: 5),
            baseURLTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            baseURLTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Model
            modelLabel.topAnchor.constraint(equalTo: baseURLTextField.bottomAnchor, constant: 15),
            modelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            modelPopUpButton.topAnchor.constraint(equalTo: modelLabel.bottomAnchor, constant: 5),
            modelPopUpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            modelPopUpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Language
            languageLabel.topAnchor.constraint(equalTo: modelPopUpButton.bottomAnchor, constant: 15),
            languageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            languagePopUpButton.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 5),
            languagePopUpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            languagePopUpButton.widthAnchor.constraint(equalToConstant: 200),
            
            // Temperature
            tempLabel.topAnchor.constraint(equalTo: languagePopUpButton.bottomAnchor, constant: 15),
            tempLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            temperatureSlider.topAnchor.constraint(equalTo: tempLabel.bottomAnchor, constant: 5),
            temperatureSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            temperatureSlider.trailingAnchor.constraint(equalTo: temperatureLabel.leadingAnchor, constant: -10),
            temperatureLabel.centerYAnchor.constraint(equalTo: temperatureSlider.centerYAnchor),
            temperatureLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            temperatureLabel.widthAnchor.constraint(equalToConstant: 40),
            tempHintLabel.topAnchor.constraint(equalTo: temperatureSlider.bottomAnchor, constant: 5),
            tempHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Prompt
            promptLabel.topAnchor.constraint(equalTo: tempHintLabel.bottomAnchor, constant: 15),
            promptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 5),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 60),
            promptHintLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 5),
            promptHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Buttons
            buttonContainer.topAnchor.constraint(equalTo: promptHintLabel.bottomAnchor, constant: 20),
            buttonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            buttonContainer.heightAnchor.constraint(equalToConstant: 32),
            
            cancelButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -20),
            saveButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -10)
        ])
    }
    
    private func loadSettings() {
        apiKeyTextField.stringValue = userDefaults.string(forKey: "whisper_api_key") ?? ""
        baseURLTextField.stringValue = userDefaults.string(forKey: "whisper_base_url") ?? "https://api.openai.com"
        
        let model = userDefaults.string(forKey: "whisper_model") ?? "whisper-large-v3"
        selectModel(model)
        
        let language = userDefaults.string(forKey: "whisper_language") ?? ""
        selectLanguage(language)
        
        let temperature = userDefaults.double(forKey: "whisper_temperature")
        if temperature == 0 && !userDefaults.bool(forKey: "whisper_temperature_set") {
            temperatureSlider.doubleValue = 0.2
        } else {
            temperatureSlider.doubleValue = temperature
        }
        temperatureChanged(temperatureSlider)
        
        promptTextView.string = userDefaults.string(forKey: "whisper_prompt") ?? ""
    }
    
    private func selectModel(_ model: String) {
        switch model {
        case "whisper-large-v3":
            modelPopUpButton.selectItem(at: 0)
        case "whisper-1":
            modelPopUpButton.selectItem(at: 1)
        case "distil-whisper-large-v3-en":
            modelPopUpButton.selectItem(at: 2)
        default:
            modelPopUpButton.selectItem(at: 0)
        }
    }
    
    private func selectLanguage(_ language: String) {
        switch language {
        case "": languagePopUpButton.selectItem(at: 0)
        case "zh": languagePopUpButton.selectItem(at: 1)
        case "en": languagePopUpButton.selectItem(at: 2)
        case "es": languagePopUpButton.selectItem(at: 3)
        case "fr": languagePopUpButton.selectItem(at: 4)
        case "de": languagePopUpButton.selectItem(at: 5)
        case "ja": languagePopUpButton.selectItem(at: 6)
        case "ko": languagePopUpButton.selectItem(at: 7)
        default: languagePopUpButton.selectItem(at: 0)
        }
    }
    
    @objc private func temperatureChanged(_ sender: NSSlider) {
        temperatureLabel.stringValue = String(format: "%.1f", sender.doubleValue)
    }
    
    @objc private func saveSettings(_ sender: NSButton) {
        userDefaults.set(apiKeyTextField.stringValue, forKey: "whisper_api_key")
        userDefaults.set(baseURLTextField.stringValue, forKey: "whisper_base_url")
        userDefaults.set(getSelectedModel(), forKey: "whisper_model")
        userDefaults.set(getSelectedLanguage(), forKey: "whisper_language")
        userDefaults.set(temperatureSlider.doubleValue, forKey: "whisper_temperature")
        userDefaults.set(true, forKey: "whisper_temperature_set")
        userDefaults.set(promptTextView.string, forKey: "whisper_prompt")
        
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        window?.close()
    }
    
    @objc private func cancelSettings(_ sender: NSButton) {
        window?.close()
    }
    
    private func getSelectedModel() -> String {
        switch modelPopUpButton.indexOfSelectedItem {
        case 0: return "whisper-large-v3"
        case 1: return "whisper-1"
        case 2: return "distil-whisper-large-v3-en"
        default: return "whisper-large-v3"
        }
    }
    
    private func getSelectedLanguage() -> String {
        switch languagePopUpButton.indexOfSelectedItem {
        case 0: return ""
        case 1: return "zh"
        case 2: return "en"
        case 3: return "es"
        case 4: return "fr"
        case 5: return "de"
        case 6: return "ja"
        case 7: return "ko"
        default: return ""
        }
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSTextViewDelegate
extension PreferencesWindowController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        // Handle text changes if needed
    }
}