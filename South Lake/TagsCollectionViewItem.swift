//
//  TagsCollectionViewItem.swift
//  South Lake
//
//  Created by Philip Dow on 3/10/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TagsCollectionViewItem: NSCollectionViewItem {
    @IBOutlet var backgroundView: CustomizableView!
    @IBOutlet var levelIndicator: TagsLevelIndicator!

    var target: AnyObject?
    var doubleAction: Selector?

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.backgroundColor = NSColor(white: 1.0, alpha: 1.0)
        backgroundView.borderColor = NSColor(white:0.8, alpha: 1.0)
        backgroundView.borderRadius = 3
        backgroundView.borderWidth = 1
    }
    
    // Prototypes don't connect outlets so we do it manually
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: TagsCollectionViewItem = super.copyWithZone(zone) as! TagsCollectionViewItem
        
        copy.backgroundView = copy.view.viewWithIdentifier("background") as! CustomizableView
        copy.backgroundView.backgroundColor = backgroundView.backgroundColor
        copy.backgroundView.borderColor = backgroundView.borderColor
        copy.backgroundView.borderRadius = backgroundView.borderRadius
        copy.backgroundView.borderWidth = backgroundView.borderWidth
        
        copy.levelIndicator = copy.view.viewWithIdentifier("levelIndicator") as! TagsLevelIndicator
        copy.levelIndicator.bind("count", toObject: copy, withKeyPath: "representedObject.count", options: [:])
        
        copy.doubleAction = doubleAction
        copy.target = target
        
        return copy
    }
    
    // MARK: - State
    
    override var selected: Bool {
        didSet {
            guard (backgroundView as NSView?) != nil else {
                return
            }
            backgroundView.borderColor = selected
                ? NSColor(forControlTint: .DefaultControlTint)
                : NSColor(white:0.8, alpha: 1.0)
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        guard theEvent.clickCount == 2 else {
            super.mouseDown(theEvent)
            return
        }
        guard let target = target as? NSObject,
              let doubleAction = doubleAction else {
            return
        }
        target.performSelector(doubleAction, withObject: self)
    }
    
}
