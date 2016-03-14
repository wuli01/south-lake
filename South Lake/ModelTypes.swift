//
//  ModelTypes.swift
//  South Lake
//
//  Created by Philip Dow on 3/13/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

struct DataTypes {
    struct DataSource {
        static let mime = "southlake/x-source-item"
        static let uti = "southlake.source-item"
        static let model = "datasource"
    }
    struct Section {
        static let mime = "southlake/x-section"
        static let uti = "southlake.section"
        static let model = "section"
    }
    struct Folder {
        static let mime = "southlake/x-folder"
        static let uti = "southlake.folder"
        static let model = "folder"
    }
    struct SmartFolder {
        static let mime = "southlake/x-smart-folder"
        static let uti = "southlake.smart-folder"
        static let model = "smart_folder"
    }
    struct File {
        static let mime = "southlake/x-file"
        static let uti = "southlake.file"
        static let model = "file"
    }
    
    struct Library {
        static let mime = "southlake/x-notebook-library"
        static let uti = "southlake.notebook.library"
        static let ext = "southlake-notebook-library"
    }
    struct Calendar {
        static let mime = "southlake/x-notebook-calendar"
        static let uti = "southlake.notebook.calendar"
        static let ext = "southlake-notebook-calendar"
    }
    struct Tags {
        static let mime = "southlake/x-notebook-tags"
        static let uti = "southlake.notebook.tags"
        static let ext = "southlake-notebook-tags"
    }
    struct Trash {
        static let mime = "southlake/x-notebook-trash"
        static let uti = "southlake.notebook.trash"
        static let ext = "southlake-notebook-trash"
    }
    
    struct Markdown {
        static let mime = "text/markdown"
        static let ext = "markdown"
        static let uti = "net.daringfireball.markdow"
        static let model = "text/markdown"
        
    }
}