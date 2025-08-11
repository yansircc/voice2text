import Cocoa

class TextInsertionService {
    private var lastInsertedText: String = ""
    private let undoManager = UndoManager()
    
    @MainActor
    func insertPlaceholder(_ placeholder: String) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for character in placeholder {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                let utf16Chars = Array(String(character).utf16)
                event.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                event.post(tap: .cgAnnotatedSessionEventTap)
            }
        }
    }
    
    @MainActor
    func removePlaceholder(_ text: String = "[转录中...]") {
        let placeholderLength = text.count
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Use backspace to delete the placeholder text
        let deleteKey: CGKeyCode = 0x33 // Delete/Backspace key
        
        for _ in 0..<placeholderLength {
            if let deleteEvent = CGEvent(keyboardEventSource: source, virtualKey: deleteKey, keyDown: true) {
                deleteEvent.post(tap: .cgAnnotatedSessionEventTap)
            }
            if let deleteEventUp = CGEvent(keyboardEventSource: source, virtualKey: deleteKey, keyDown: false) {
                deleteEventUp.post(tap: .cgAnnotatedSessionEventTap)
            }
            // Small delay between deletions
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
    
    @MainActor
    func insertText(_ text: String) {
        // Store for undo support
        lastInsertedText = text
        
        // Use pasteboard method for better undo support
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Save current pasteboard content
        let previousContent = NSPasteboard.general.string(forType: .string)
        
        // Set new content
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        // Simulate Cmd+V
        let vKey: CGKeyCode = 0x09
        if let pasteEvent = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true) {
            pasteEvent.flags = .maskCommand
            pasteEvent.post(tap: .cgAnnotatedSessionEventTap)
        }
        
        if let pasteEventUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) {
            pasteEventUp.flags = .maskCommand
            pasteEventUp.post(tap: .cgAnnotatedSessionEventTap)
        }
        
        // Restore previous pasteboard content after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let previousContent = previousContent {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(previousContent, forType: .string)
            }
        }
    }
    
    func getLastInsertedText() -> String {
        return lastInsertedText
    }
}