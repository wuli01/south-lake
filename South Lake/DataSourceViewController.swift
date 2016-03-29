//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

//  TODO: mark DataSourceViewController protocol as always belonging to class NSViewController
//  TODO: blows up when I make available to @objc(DataSourceViewController)

/// ### Architecture
/// Sharing full File data model rather than just the file contents so that the
/// editor has the ability to modify model metadata as file contents are edited

protocol DataSourceViewController: class, Databasable {
    
    static var filetypes: [String] { get }
    static var storyboard: String { get }
    
    /// A DataSourceViewController is a view controller with a view property
    var view: NSView { get set }
    
    /// A DataSourceViewController is a view controller that can handle child-parent relationships
    func removeFromParentViewController()
    
    /// A tab passes a file to the editor. The file may be nil. The editor may
    /// many any changes it likes to the file, including metadata changes.
    /// Editors should use the universal data: NSData interface for file contents
    
    var source: DataSource? { get set }
    
    /// A data source communicates changes in selection to observers using
    /// delegate methods. Bindings were in use but the binding firing when
    /// established is undesirable
    
    var delegate: SelectionDelegate? { get set }
    
    /// The responder that take focus for editing and first responder switching
    var primaryResponder: NSView { get }
    
    // These three really belong to folder source viewers and not file source viewers {
    
        /// Return true if we edit files specifically and not some other kind of data source
        var isFileEditor: Bool { get }
        
        /// Some source viewers can themselves have selected objects. This variable should be dynamic
        var selectedObjects: [DataSource]? { get set }
        
        /// Some source viewers may change their presentation based on the scene
        var scene: Scene { get set }
    
        /// Some source viewers may change their presentation based on the layout
        var layout: Layout { get set }
    
    // }
    
    /// A file editor can return inspectors that it manages which are placed in the inspector area
    /// An inspector consists of a tile, and icon and a view controller
    /// A metadata inspector is automatically included in the inspector area
    var inspectors: [Inspector]? { get }
    
    /// A file editor should take special action if a search is being performed, 
    /// such as highlighting the search term
    func performSearch(text: String?, results: BRSearchResults?)
    
    /// In most cases a file editor won't need to handle open urls but some of the 
    /// special editors such as the library and tag editors do need to
    func openURL(url: NSURL)
    
    /// Called immediately before the editor is removed from the view hierarchy
    /// Editors should clean up, for example, unbinding
    func willClose()
}
