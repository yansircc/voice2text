import Cocoa

protocol GlobalKeyboardMonitorDelegate: AnyObject {
    func keyboardMonitor(_ monitor: GlobalKeyboardMonitor, fnKeyPressed: Bool)
}

class GlobalKeyboardMonitor {
    weak var delegate: GlobalKeyboardMonitorDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var fnKeyDown = false
    private var monitoringQueue = DispatchQueue(label: "keyboard.monitor.queue", qos: .userInteractive)
    
    // Key codes
    private let kFnKeyCode: CGKeyCode = 0x3F  // Fn key
    private let kF5KeyCode: CGKeyCode = 0x60  // F5 key
    
    func start() {
        monitoringQueue.async { [weak self] in
            self?.setupEventTap()
        }
    }
    
    func stop() {
        monitoringQueue.async { [weak self] in
            self?.cleanupEventTap()
        }
    }
    
    private func setupEventTap() {
        // Create an event tap to monitor keyboard events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        // Create the event tap
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Get the monitor instance from refcon
                let monitor = Unmanaged<GlobalKeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        // Create a run loop source and add to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Start the run loop
        CFRunLoopRun()
    }
    
    private func cleanupEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        CFRunLoopStop(CFRunLoopGetCurrent())
        
        eventTap = nil
        runLoopSource = nil
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle different event types
        switch type {
        case .flagsChanged:
            // Check for Fn key state change
            let flags = event.flags
            let fnPressed = flags.contains(.maskSecondaryFn)
            
            if fnPressed != fnKeyDown {
                fnKeyDown = fnPressed
                
                // Notify delegate on main queue
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.keyboardMonitor(self, fnKeyPressed: self.fnKeyDown)
                }
            }
            
        case .keyDown:
            // Check for F5 key as alternative
            if event.getIntegerValueField(.keyboardEventKeycode) == kF5KeyCode {
                // Check if we should intercept F5
                let flags = event.flags
                
                // If no modifiers, intercept F5 for our use
                if !flags.contains(.maskCommand) && !flags.contains(.maskControl) && !flags.contains(.maskAlternate) {
                    // Start recording
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.keyboardMonitor(self, fnKeyPressed: true)
                    }
                    
                    // Suppress the original F5 event
                    return nil
                }
            }
            
        case .keyUp:
            // Check for F5 key release
            if event.getIntegerValueField(.keyboardEventKeycode) == kF5KeyCode {
                let flags = event.flags
                
                if !flags.contains(.maskCommand) && !flags.contains(.maskControl) && !flags.contains(.maskAlternate) {
                    // Stop recording
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.keyboardMonitor(self, fnKeyPressed: false)
                    }
                    
                    // Suppress the original F5 event
                    return nil
                }
            }
            
        case .tapDisabledByTimeout:
            // Re-enable the event tap if it gets disabled by timeout
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            
        default:
            break
        }
        
        // Return the event unmodified (except when we return nil above)
        return Unmanaged.passUnretained(event)
    }
    
    deinit {
        stop()
    }
}