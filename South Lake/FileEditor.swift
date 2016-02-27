//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

//  TODO: mark FileEditor protocol as always belonging to class NSViewController
//  TODO: blows up when I make available to @objc(FileEditor)

/// ### Architecture
/// Sharing full File data model rather than just the file contents so that the
/// editor has the ability to modify model metadata as file contents are edited

protocol FileEditor {
    
    static var filetypes: [String] { get }
    static var storyboard: String { get }
    
    /// A tab passes a file to the editor. The file may be nil. The editor may
    /// many any changes it likes to the file, including metadata changes.
    /// Editors should use the universal data: NSData interface for file contents
    
    var file: File? { get set }
    
    /// Editors may do something differently when they are working with a newly
    /// created document rather than a previously existing one.
    
    var newDocument: Bool { get set }
}