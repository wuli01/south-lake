//
//  DocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class DocumentTab: NSViewController {
    var databaseManager: DatabaseManager! {
        didSet {
        
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
        
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // Manage document state, primarily user interface state
    
    func state() -> Dictionary<String,AnyObject> {
        return ["Title": (title ?? "")]
    }
}
