//
//  CalendarEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class CalendarEditor: NSViewController, SourceViewer {
    @IBOutlet var containerView: NSView!

    static var filetypes: [String] { return ["southlake.notebook.calendar", "southlake/x-notebook-calendar", "southlake-notebook-calendar"] }
    static var storyboard: String { return "CalendarEditor" }
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // TODO: what is this used for?
    
    var isFileEditor: Bool {
        return false
    }
    
    dynamic var selectedObjects: [DataSource]?
    
    dynamic var source: DataSource?
        
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        return nil
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = UI.Color.SourceViewerBackground
    }
    
    // MARK: - 
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
    
    }
    
    func willClose() {
    
    }
}
