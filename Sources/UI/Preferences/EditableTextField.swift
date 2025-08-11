import Cocoa

// Custom NSTextField that handles copy/paste operations for menu bar apps
class EditableNSTextField: NSTextField {
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown {
            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Check for Cmd key combinations
            if modifierFlags == .command {
                switch event.charactersIgnoringModifiers {
                case "v":
                    // Paste
                    if let pasteboard = NSPasteboard.general.string(forType: .string) {
                        self.currentEditor()?.insertText(pasteboard)
                        return true
                    }
                case "c":
                    // Copy
                    if let selectedRange = self.currentEditor()?.selectedRange,
                       selectedRange.length > 0 {
                        let text = self.stringValue
                        let startIndex = text.index(text.startIndex, offsetBy: selectedRange.location)
                        let endIndex = text.index(startIndex, offsetBy: selectedRange.length)
                        let selectedText = String(text[startIndex..<endIndex])
                        
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(selectedText, forType: .string)
                        return true
                    }
                case "x":
                    // Cut
                    if let selectedRange = self.currentEditor()?.selectedRange,
                       selectedRange.length > 0 {
                        let text = self.stringValue
                        let startIndex = text.index(text.startIndex, offsetBy: selectedRange.location)
                        let endIndex = text.index(startIndex, offsetBy: selectedRange.length)
                        let selectedText = String(text[startIndex..<endIndex])
                        
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(selectedText, forType: .string)
                        self.currentEditor()?.delete(nil)
                        return true
                    }
                case "a":
                    // Select All
                    self.currentEditor()?.selectAll(nil)
                    return true
                case "z":
                    // Undo
                    self.undoManager?.undo()
                    return true
                default:
                    break
                }
            } else if modifierFlags == [.command, .shift] {
                if event.charactersIgnoringModifiers == "z" {
                    // Redo
                    self.undoManager?.redo()
                    return true
                }
            }
        }
        
        return super.performKeyEquivalent(with: event)
    }
}

// Custom NSSecureTextField that handles copy/paste operations
class EditableNSSecureTextField: NSSecureTextField {
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown {
            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Check for Cmd key combinations
            if modifierFlags == .command {
                switch event.charactersIgnoringModifiers {
                case "v":
                    // Paste
                    if let pasteboard = NSPasteboard.general.string(forType: .string) {
                        self.currentEditor()?.insertText(pasteboard)
                        return true
                    }
                case "c":
                    // Copy - Note: Usually disabled for secure fields, but we'll allow it
                    if let selectedRange = self.currentEditor()?.selectedRange,
                       selectedRange.length > 0 {
                        let text = self.stringValue
                        let startIndex = text.index(text.startIndex, offsetBy: selectedRange.location)
                        let endIndex = text.index(startIndex, offsetBy: selectedRange.length)
                        let selectedText = String(text[startIndex..<endIndex])
                        
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(selectedText, forType: .string)
                        return true
                    }
                case "x":
                    // Cut
                    if let selectedRange = self.currentEditor()?.selectedRange,
                       selectedRange.length > 0 {
                        let text = self.stringValue
                        let startIndex = text.index(text.startIndex, offsetBy: selectedRange.location)
                        let endIndex = text.index(startIndex, offsetBy: selectedRange.length)
                        let selectedText = String(text[startIndex..<endIndex])
                        
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(selectedText, forType: .string)
                        self.currentEditor()?.delete(nil)
                        return true
                    }
                case "a":
                    // Select All
                    self.currentEditor()?.selectAll(nil)
                    return true
                case "z":
                    // Undo
                    self.undoManager?.undo()
                    return true
                default:
                    break
                }
            } else if modifierFlags == [.command, .shift] {
                if event.charactersIgnoringModifiers == "z" {
                    // Redo
                    self.undoManager?.redo()
                    return true
                }
            }
        }
        
        return super.performKeyEquivalent(with: event)
    }
}