//
//  CustomizableView.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class CustomizableView: NSView {
    
    static let keylessColor = UI.Color.Selection.NotKeyView
    
    var backgroundColor: NSColor? = NSColor(white: 1.0, alpha: 1.0) {
        didSet {
            needsDisplay = true
        }
    }
    
    var borderColor: NSColor? {
        didSet {
            needsDisplay = true
        }
    }
    
    var borderWidth: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    var borderRadius: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    /// Dim selection color to a default gray whenever this view and its superviews
    /// aren't in the responder chain
    
    var dimsSelection: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
            NSRectFill(dirtyRect)
        }
        if let borderColor = borderColor {
            let rect = NSInsetRect(bounds, borderWidth/2, borderWidth/2)
            let path = NSBezierPath(roundedRect: rect, xRadius: borderRadius, yRadius: borderRadius)
            path.lineWidth = borderWidth
            
            if dimsSelection && !inResponderChain {
                CustomizableView.keylessColor.set()
            } else {
                borderColor.set()
            }
            
            path.stroke()
        }
        
        super.drawRect(dirtyRect)
    }
    
}
