//
//  TagsCollectionViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: obvious need for factorization, this is not a FileCollectionScene

import Cocoa

class TagsCollectionViewController: NSViewController, FileCollectionScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - File Collection Scene

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    var selectionDelegate: SelectionDelegate?
    var selectsOnDoubleClick: Bool = false {
        didSet {
            if selectsOnDoubleClick {
                unbind("selectedObjects")
            } else {
                bind("selectedObjects", toObject: arrayController, withKeyPath: "selectedObjects", options: [:])
            }
        }
    }
    
    // TODO: These aren't actually DataSource, they're [String: Object]
    
    dynamic var selectedObjects: [DataSource] = [] {
        didSet {
            if let selectionDelegate = selectionDelegate {
                selectionDelegate.object(self, didChangeSelection: selectedObjects)
            }
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.backgroundColors = [UI.Color.Background.SourceViewer]
        
        let prototype = storyboard!.instantiateControllerWithIdentifier("tagsListCollectionViewItem") as? TagsCollectionViewItem
        prototype?.doubleAction = #selector(TagsCollectionViewController.doubleClick(_:))
        prototype?.target = self
        
        collectionView.itemPrototype = prototype
    }
    
    func willClose() {
        // OS API bug: 
        // collectionView.itemPrototype must be set to nil for collection view
        // and this view controller to dealloc, but first the content on the
        // array controller must be emptied (see unloadScene())
        collectionView.unbind("content")
        collectionView.unbind("selectionIndexes")
        collectionView.itemPrototype = nil
    }
    
    // MARK: -
    
    func minimize() {
    
    }
    
    func maximize() {
    
    }
    
    // MARK: -
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard selectsOnDoubleClick else {
            return
        }
        guard arrayController.selectedObjects.count > 0 else {
            return
        }
        guard let selection = arrayController.selectedObjects as? [DataSource] else {
            return
        }
        
        selectedObjects = selection
    }
    
//    @IBAction func doubleClick(sender: AnyObject?) {
//        guard selectsOnDoubleClick else {
//            return
//        }
//        guard let databaseManager = databaseManager else {
//            return
//        }
//        guard let object = arrayController.selectedObjects[safe: 0] as? [String:AnyObject],
//              let tag = object["tag"] as? String,
//              let encodedTag = tag.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
//            log("no selected object")
//            return
//        }
//        guard let url = NSURL(string: "southlake://localhost/tags/\(encodedTag)") else {
//            log("unable to construct url for object with id \(encodedTag)")
//            return
//        }
//        
//        // TODO: Track history
//        
//        log(url)
//        
//        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
//            "dbm": databaseManager,
//            "url": url
//        ])
//    }
    
    // MARK: - View
    
    var usingIconView: Bool = true
    
    func useIconView() {
        collectionView.maxItemSize = NSMakeSize(227, 33)
        collectionView.maxNumberOfColumns = 0
    }
    
    func useListView() {
        collectionView.maxItemSize = NSMakeSize(0, 33)
        collectionView.maxNumberOfColumns = 1
    }

}

extension TagsCollectionViewController: NSCollectionViewDelegate {
    
    // This method is inexplicably not called

    func collectionView(collectionView: NSCollectionView, didSelectItemsAtIndexPaths indexPaths: Set<NSIndexPath>) {
        log("call me baby")
        
        guard let selection = arrayController.selectedObjects as? [DataSource] else {
            return
        }
        guard !selectsOnDoubleClick else {
            return
        }
        
        selectedObjects = selection
    }
}
