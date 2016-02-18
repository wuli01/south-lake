//
//  SmartFolder.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(SmartFolder)
class SmartFolder: Folder {
    override class var model_mime_type: NSString { return "private/smart-folder" }
    override class var model_uti: NSString { return "private.smart-folder" }
    
    @NSManaged var predicates: [String]
}
