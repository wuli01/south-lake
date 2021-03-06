//
//  DocumentTabController.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Create and destroy tabs, persist and restore them.

//  TODO: Generic methods for creating tabs from storyboards or classes
//        to suppport plugin architecture rather than for creating
//        specific kinds of tabs

import Cocoa

enum DocumentTabControllerError: ErrorType {
    case CouldNotInstantiateTabViewController
}

class DocumentTabController: NSViewController, Databasable {
    @IBOutlet var tabBarView: MMTabBarView!
    @IBOutlet var tabView: NSTabView!
    
    var databaseManager: DatabaseManager? {
        didSet {
            for vc in tabs {
                vc.databaseManager = databaseManager
            }
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            for vc in tabs {
                vc.searchService = searchService
            }
        }
    }
    
    // TODO: invariant: always have a selected tab (but not when state is being restored)
    
    var selectedTab: DocumentTab? {
        return tabView.selectedTabViewItem?.vc as? DocumentTab
    }
    
    var tabs: [DocumentTab] {
        return tabView.tabViewItems.map {($0.vc as! DocumentTab)}
    }
    
    var count: Int {
        return tabs.count
    }
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearTabs()
        
        tabBarView.setStyleNamed("Yosemite")
        tabBarView.setShowAddTabButton(true)
        tabBarView.setOrientation(MMTabBarHorizontalOrientation)
        tabBarView.setHideForSingleTab(false)
        tabBarView.setAllowsBackgroundTabClosing(true)
        tabBarView.setAutomaticallyAnimates(true)
        tabBarView.setOnlyShowCloseOnHover(true)
        tabBarView.setDisableTabClose(false)
        tabBarView.setButtonMinWidth(100)
        tabBarView.setButtonMaxWidth(280)
        tabBarView.setButtonOptimumWidth(130)
        
        do { try createNewTabWithTitle("Tab One") } catch {
            log("viewDidLoad: could not create new tab")
        }
    }
    
    // MARK: - Tab Actions
    
    @IBAction func createNewTab(sender: AnyObject?) {
        do { try createNewTabWithTitle(NSLocalizedString("Untitled", comment: "Untitled tab")) } catch {
            log("createNewTab: could not create new tab")
        }
    }
    
    @IBAction func performClose(sender: AnyObject?) {
        closeTab(sender)
    }
    
    @IBAction func closeTab(sender: AnyObject?) {
        guard tabView.tabViewItems.count > 1 else {
            return
        }
        guard let tabViewItem = tabView.selectedTabViewItem else {
            return
        }
        
        tabViewItem.identifier.unbind("title")
        tabViewItem.identifier.unbind("icon")
        
        tabView.removeTabViewItem(tabViewItem)
    }
    
    @IBAction func selectNextTab(sender: AnyObject?) {
        if tabView.indexOfTabViewItem(tabView.selectedTabViewItem!) == tabView.numberOfTabViewItems-1 {
            tabView.selectFirstTabViewItem(sender)
        } else {
            tabView.selectNextTabViewItem(sender)
        }
    }
    
    @IBAction func selectPreviousTab(sender: AnyObject?) {
        if tabView.indexOfTabViewItem(tabView.selectedTabViewItem!) == 0 {
            tabView.selectLastTabViewItem(sender)
        } else {
            tabView.selectPreviousTabViewItem(sender)
        }
    }
    
    // MARK: - Routable User Actions
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        selectedTab?.createNewMarkdownDocument(sender)
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject?) {
        selectedTab?.createNewSmartFolder(sender)
    }
    
    @IBAction func createNewFolder(sender: AnyObject?) {
        selectedTab?.createNewFolder(sender)
    }
    
    @IBAction func makeFilesAndFoldersFirstResponder(sender: AnyObject?) {
        selectedTab?.makeFilesAndFoldersFirstResponder(sender)
    }
    
    @IBAction func makeEditorFirstResponder(sender: AnyObject?) {
        selectedTab?.makeEditorFirstResponder(sender)
    }
    
    @IBAction func makeFileInfoFirstResponder(sender: AnyObject?) {
        selectedTab?.makeFileInfoFirstResponder(sender)
    }
    
    @IBAction func changeLayout(sender: AnyObject?) {
        selectedTab?.changeLayout(sender)
    }
    
    @IBAction func toggleDocumentHeader(sender: AnyObject?) {
        selectedTab?.toggleDocumentHeader(sender)
    }
    
    // MARK: -
    
    func handleOpenURLNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let dbm = userInfo["dbm"] as? DatabaseManager,
              //let _ = userInfo["source"] as? DataSource,
              let _ = userInfo["url"] as? NSURL
              where dbm == databaseManager else {
            log("open url notification does not contain dbm or url")
            return
        }
        
        selectedTab?.handleOpenURLNotification(notification)
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(DocumentTabController.createNewMarkdownDocument(_:)),
             #selector(DocumentTabController.createNewSmartFolder(_:)),
             #selector(DocumentTabController.createNewFolder(_:)),
             #selector(DocumentTabController.makeFilesAndFoldersFirstResponder(_:)),
             #selector(DocumentTabController.makeEditorFirstResponder(_:)),
             #selector(DocumentTabController.makeFileInfoFirstResponder(_:)),
             #selector(DocumentTabController.changeLayout(_:)),
             #selector(DocumentTabController.toggleDocumentHeader(_:)):
             return selectedTab != nil
                ? selectedTab!.validateMenuItem(menuItem)
                : false
        case #selector(DocumentTabController.closeTab(_:)),
             #selector(DocumentTabController.createNewTab(_:)):
             return true
        case #selector(DocumentTabController.selectNextTab(_:)),
             #selector(DocumentTabController.selectPreviousTab(_:)):
             return count > 1
        default:
             return false
        }
    }
    
    // MARK: - Tab Utiltiies
    
    func createNewTabWithTitle(title: String) throws {
        if let tab = try createNewTab() {
            tab.vc!.title = title
        }
    }
    
    func createNewTab() throws -> NSTabViewItem? {
        guard let viewController = NSStoryboard(name: "DefaultTab", bundle: nil).instantiateInitialController() as? NSViewController else {
            throw DocumentTabControllerError.CouldNotInstantiateTabViewController
        }
        guard viewController is DocumentTab else {
            throw DocumentTabControllerError.CouldNotInstantiateTabViewController
        }
        
        let tabBarItem = DocumentTabBarItem()
        let tabViewItem = NSTabViewItem(identifier: tabBarItem)
        
        tabViewItem.view = viewController.view
        tabViewItem.vc = viewController
        
        tabBarItem.bind("title", toObject: viewController, withKeyPath: "title", options: [:])
        tabBarItem.bind("icon", toObject: viewController, withKeyPath: "icon", options: [:])
        
        (viewController as! DocumentTab).databaseManager = databaseManager
        (viewController as! DocumentTab).searchService = searchService
        
        // For example, we don't have to select
        
        tabView.addTabViewItem(tabViewItem)
        tabView.selectTabViewItem(tabViewItem)
        
        return tabViewItem
    }
    
    func clearTabs() {
        for (item) in tabView.tabViewItems {
            tabView.removeTabViewItem(item)
        }
    }
    
    // MARK: - Document State
    
    func state() -> Dictionary<String,AnyObject> {
        var tabStates: [AnyObject] = []
        
        for vc in tabs {
            tabStates.append(vc.state())
        }
        
        return ["Tabs": tabStates]
    }
    
    func restoreState(state: Dictionary<String,AnyObject>) {
        if let tabStates = state["Tabs"] as? [Dictionary<String,AnyObject>] {
            clearTabs()
            
            for tabState in tabStates {
                do {
                    if  let tab = try createNewTab(),
                        let vc = tab.vc as? DocumentTab {
                        vc.restoreState(tabState)
                    }
                } catch {
                    log("restoreState: unable to restore a tab")
                }
            }
        }
        
        // TODO: error checking. In case of corrupion, provide default state
    }
}

// MARK: - MMTabBarViewDelegate

extension DocumentTabController: MMTabBarViewDelegate {
    
    func addNewTabToTabView(tabView: NSTabView) {
        createNewTab(tabView)
    }
    
    func tabView(aTabView: NSTabView!, didCloseTabViewItem tabViewItem: NSTabViewItem!) {
        if let tab = tabViewItem.vc as? DocumentTab {
            tab.willClose()
        }
    }
    
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        // log("didSelectTabViewItem: \(tabViewItem!.label)")
    }
}

// MARK: - DocumentTabBarItem

class DocumentTabBarItem: NSObject, MMTabBarItem {
    var title: String = NSLocalizedString("Untitled", comment: "Untitled tab")
    var hasCloseButton: Bool = true
    var icon: NSImage?
    
    override init() {
        super.init()
    }
    
    init(title: String) {
        self.title = title
    }
}
