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
                "storyboard": "MarkdownEditor",
                "filetypes": [
                    "net.daringfireball.markdown",
                    "markdown",
                    "text/markdown"
                ]
            ],
            [
                "storyboard": "PDFEditor",
                "filetypes": [
                    "com.adobe.pdf",
                    "pdf",
                    "application/pdf"
                ]
            ],
            [
                "storyboard": "LibraryEditor",
                "filetypes": [
                    "southlake.notebook.library",
                    "southlake/x-notebook-library",
                    "southlake-notebook-library"
                ]
            ],
            [
                "storyboard": "TagsEditor",
                "filetypes": [
                    "southlake.notebook.tags",
                    "southlake/x-notebook-tags",
                    "southlake-notebook-tags"
                ],
                
            ],
            [
                "storyboard": "CalendarEditor",
                "filetypes": [
                    "southlake.notebook.calendar",
                    "southlake/x-notebook-calendar",
                    "southlake-notebook-calendar"
                ]
            ],
            [
                "storyboard": "FolderEditor",
                "filetypes": [
                    "southlake.folder",
                    "southlake/x-folder",
                    "southlake-folder",
                    "southlake.smart-folder",
                    "southlake/x-smart-folder",
                    "southlake-smart-folder",
                    "southlake/x-notebook-inbox",
                    "southlake.notebook.inbox",
                    "southlake-notebook-inbox"
                ]
            ],
            [
                "storyboard": "TagEditor",
                "filetypes": [
                    "southlake/x-tag",
                    "southlake-tag",
                    "southlake.tag"
                ]
            ]
        ]
    }
    
    func plugInForFiletype(filetype: String) -> SourceViewer? {
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
        
        return NSStoryboard(name: storyboard!, bundle: nil).instantiateInitialController() as? SourceViewer
    }
}
