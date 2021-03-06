//
//  PDFEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import Quartz

class PDFEditor: NSViewController, SourceViewer {
    static var storyboard: String = "PDFEditor"
    static var filetypes: [String] = [
        "com.adobe.pdf",
        "pdf",
        "application/pdf"
    ]
    
    @IBOutlet var editor: PDFView!
    
    // MARK: - File Editor

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    dynamic var source: DataSource? {
        didSet {
            loadFile(source)
        }
    }
    
    var layout: Layout = .None
    var scene: Scene = .None
    
    var primaryResponder: NSView {
        return editor
    }
    
    var inspectors: [Inspector]? {
        loadThumbnailInspector()
        guard let vc = thumbnailInspector else {
            return nil
        }
        return [vc]
    }
    
    // MARK: - My Properties

    var thumbnailInspector: PDFThumbnailInspector?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        editor.setBackgroundColor(UI.Color.Background.SourceViewer)
        editor.setAutoScales(true)
        
        loadFile(source)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
//        NSOperationQueue.mainQueue().addOperationWithBlock {
//            self.editor.goToFirstPage(nil)
//            
//        }
    }
    
    func willClose() {
        editor.setDocument(nil)
        if let thumbnailInspector = thumbnailInspector {
            thumbnailInspector.thumbnailView.setPDFView(nil)
        }
    }
    
    // MARK: - 
    
    func loadFile(file: DataSource?) {
        guard let file = file as? File else {
            return
        }
        guard viewLoaded else {
            return
        }
        guard let document = PDFDocument(data: file.data) else {
            log("unable to initialize pdf document from file data")
            return
        }
        
        editor.setDocument(document)
    }
    
    // TODO: dynamically return individual inspector views as they are needed?
    
    func loadThumbnailInspector() {
        guard thumbnailInspector == nil else {
            return
        }
        
        thumbnailInspector = storyboard!.instantiateControllerWithIdentifier("thumbnail") as? PDFThumbnailInspector
        
        thumbnailInspector!.databaseManager = databaseManager
        thumbnailInspector!.searchService = searchService
        
        let _ = thumbnailInspector!.view
        thumbnailInspector!.thumbnailView.setPDFView(editor)
    }
    
    // MARK: - 
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
    
    }
}
