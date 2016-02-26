//
//  EditorPlugIns.swift
//  South Lake
//
//  Created by Philip Dow on 2/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class EditorPlugIns {
    static let sharedInstance = EditorPlugIns()
    private var plugins: [ [String:AnyObject] ] = []
    
    private init() {
        self.registerPlugIns()
    }
    
    func registerPlugIns() {
        // Store this information in a bundle plist
        // Just need the bundle, storyboard name and filetypes
        
        plugins = [
            [
                "filetypes": ["net.daringfireball.markdown", "markdown", "text/markdown"],
                "storyboard": "MarkdownEditor"
            ]
        ]
    }
    
    func plugInForFiletype(filetype: String) -> FileEditor? {
        var storyboard: String?
        
        for plugin in plugins {
            guard let filetypes = plugin["filetypes"] as? [String],
                  let sb = plugin["storyboard"] as? String else {
                  continue
            }
            
            if filetypes.contains(filetype) {
                storyboard = sb
                break
            }
        }
        
        guard storyboard != nil else {
            return nil
        }
        
        return NSStoryboard(name: storyboard!, bundle: nil).instantiateInitialController() as? FileEditor
    }
}