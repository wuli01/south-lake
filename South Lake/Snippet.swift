//
//  Snippet.swift
//  Snippets
//
//  Created by Philip Dow on 2/27/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

/*
Copyright (c) 2016 Philip Dow

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation

class Snippet {
    
    /// Use this constant when seeking the range for next field in a newly entered snippet
    static var NewSnippetField: Int = 0
    
    /// The content of the snippet, including field markets, placeholders, etc...
    private(set) var content: String
    
    /// The text which triggers the snippet on a tab, must contain only alphanumeric characters
    private(set) var tabTrigger: String?
    
    /// User provided description of the snippet
    var description: String?
    
    /// Unused
    private(set) var scope: String? = nil
    
    /// The user facing version of the content without field markers
    private(set) var text: String
    
    /// The number of fields in the snippet
    private var snippetFieldCount: Int = 0
    
    /// Cached regex of content with field markers replaced by capture groups
    private var captureRegex: NSRegularExpression?
    
    // MARK: - Initialization
    
    /// Initialize a snippet without a tab trigger
    init(content: String) {
        self.content = content
        self.text = content
    }
    
    /// Fully initialize a snippet
    init(content: String, tabTrigger: String?, scope: String?, description: String?) {
        self.content = content
        self.tabTrigger = tabTrigger
        self.scope = scope
        self.description = description
        
        self.text = content.snippetContentWithoutFieldMarkers()
        self.snippetFieldCount = content.snippetFieldCount()
        
        do {
            self.captureRegex = try NSRegularExpression(pattern: content
                .snippetContentReplacingFieldMarkersWithGroupExpressions()
                .stringByEscapingForRegularExpressionPattern()
                .stringByRestoringCaptureGroups()
                , options: [])
        } catch {
            log(error)
        }
    }
    
    // MARK: - Field Ranges
    
    // TODO: make it work with multiple ranges for mirrored fields
    
    /// Return the range for the next field or nil if unavilable
    /// - parameter fromField:  The field from which to locate the next or
    ///                         pevious field. Use `NewSnippetField` to advance 
    ///                         to the first field
    /// - parameter forward:    Find the range for the next field (`true`) or 
    ///                         previous field (`false`).
    /// - parameter inString:   The user text being scanned.
    /// - parameter atIndex:    The location at inString from which to look for 
    ///                         the next field.
    
    func rangeForNextField(fromField field: Int, forward: Bool, inString string: String, atIndex index: String.Index) -> Range<String.Index>? {
        
        // Done if there are no fields
        
        guard snippetFieldCount > 0 else {
            return nil
        }
        
        // Done if the index is beyond the bounds of the current string
        
        guard index >= string.startIndex && index <= string.endIndex else {
            return nil
        }
        
        // Done if the last field wants to move forward
        
        if field == snippetFieldCount && forward {
            return nil
        }
        
        // Done if the first field wants to move backwards
        
        if field == 1 && !forward {
            return nil
        }
        
        // The target field is the next available field forwards or backwards
        
        let targetField = forward ? field + 1 : field - 1
        
        // Find the index of the targetField in the content
        
        guard let targetFieldIndex = content.snippetIndexOfField(targetField) else {
            if _isDebugAssertConfiguration() { log("unable to locate field: \(targetField)") }
            return nil
        }
        
        // Find the matches in the string using content with field markers replaced by capture groups
        
        guard let captureRegex = captureRegex else {
            if _isDebugAssertConfiguration() { log("no capture group regex available") }
            return nil
        }
        
        let fromRange = string.NSRangeFromRange(string.rangeFrom(index))
        let matches = captureRegex.matchesInString(string, options: [], range: fromRange)
        
        guard let match = matches[safe: 0] else {
            if _isDebugAssertConfiguration() { log("content not found in string") }
            return nil
        }
        
        // Ensure that our match contains a capture group at the target field index
        // The first result in the match is always the content itself
        
        guard match.numberOfRanges >= targetFieldIndex + 1 else {
            if _isDebugAssertConfiguration() { log("field not found in string") }
            return nil
        }
        
        // Otherwise we have what we want, wrap it up
        
        let targetFieldRange = string.rangeFromNSRange(match.rangeAtIndex(targetFieldIndex + 1))
        return targetFieldRange
    }

}
