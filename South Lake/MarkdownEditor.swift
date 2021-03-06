//
//  MarkdownEditor.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Moving the MarkdownEditor to a plugin bundle is a major re-architecting
//  It means moving all the MacDown dependencies to a plugin, including frameworks,
//  storyboards, build steps, additional classes and especially the MacDown 
//  application code.

//  Do I want to do that right now or move forward on releasing an MVP?

//  TODO: blows up when I make available to @objc(MarkdownEditor)

import Cocoa
import WebKit

let LaTeXSnippet = "$$\\sum_{i=0}^{n}$1$$"
let loremSnippet = "lorem ipsum etc"

let htmlSnippet =
"<html>\n" +
"<head>\n" +
"  <title>$1</title>\n" +
"</head>\n" +
"<body>\n" +
"$2\n" +
"</body>\n" +
"</html>"

let htmlReverseSnippet =
"<html>\n" +
"<head>\n" +
"  <title>$2</title>\n" +
"</head>\n" +
"<body>\n" +
"$1\n" +
"</body>\n" +
"</html>"

extension WebView {
    var mainFrameEnclosingScrollView: NSScrollView? {
        return mainFrame.frameView.documentView.enclosingScrollView
        // enclosingScrollView
    }
}

private var MarkdownEditorContext = 0

class MarkdownEditor: NSViewController, SourceViewer {
    static var storyboard: String = "MarkdownEditor"
    static var filetypes: [String] = [
        "net.daringfireball.markdown",
        "markdown",
        "text/markdown"
    ]
    
    @IBOutlet var splitView: MPDocumentSplitView!
    @IBOutlet var editorContainer: NSView!
    @IBOutlet var editor: MPEditorView!
    @IBOutlet var preview: WebView!
    
    let MPEditorKeysToObserve: [String: Bool] = [
        "automaticDashSubstitutionEnabled": false,
        "automaticDataDetectionEnabled": false,
        "automaticQuoteSubstitutionEnabled": false,
        "automaticSpellingCorrectionEnabled": false,
        "automaticTextReplacementEnabled": false,
        "continuousSpellCheckingEnabled": false,
        "enabledTextCheckingTypes": false,
        "grammarCheckingEnabled": false
    ]
    
    var preferences: MPPreferences = MPPreferences.sharedInstance()
    var highlighter: HGMarkdownHighlighter!
    var renderer: MPRenderer!
    
    // TODO: not using initialContents
    
    var initialContents: String?
    var lastPreviewScrollTop: CGFloat = 0.0
    var shouldHandleBoundsChange: Bool = true
    var printing: Bool = false
    var copying: Bool = false
    
    var previewVisible: Bool {
        return preview.frame.size.width != 0.0
    }
    
    var editorVisible: Bool {
        return editorContainer.frame.size.width != 0.0
    }
    
    var needsHTML: Bool {
        if preferences.markdownManualRender {
            return false
        } else {
            return self.previewVisible || self.preferences.editorShowWordCount
        }
    }
    
    // TEMPORARY
    
    dynamic var tableOfContents: String?
    dynamic var tableOfContentsAnchor: String = "" {
        didSet {
            let script = "window.location.href = \"#" + tableOfContentsAnchor + "\""
            let eval = preview.stringByEvaluatingJavaScriptFromString(script)
            log("\(tableOfContentsAnchor) : \(eval)")
//            let URL = NSURL(string: "#" + tocRef)
//            preview.mainFrame.loadRequest(NSURLRequest(URL: URL!))
        }
    }
    
    var editingTemplate: Bool = false
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // It might be possible to bypass the whole data bit and just bind the editor
    // directly to the file key from interface builder
    
    var tableOfContentsInspector: MarkdownTOCInspector?
    
    var inspectors: [Inspector]? {
        loadTableOfContentsInspector()
        guard let vc = tableOfContentsInspector else {
            return nil
        }
        return [vc]
    }
    
    var layout: Layout = .None
    var scene: Scene = .None
    
    dynamic var source: DataSource? {
        willSet {
            if let source = source {
                unbindUs("data", toObject: source, withKeyPath: "data")
            }
        }
        didSet {
            if let source = source {
                bindUs("data", toObject: source, withKeyPath: "data", options: [:])
            }
        }
    }
    
    dynamic var data: NSData? {
        didSet {
            guard viewLoaded && needsHTML else {
                return
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.renderer.parseAndRenderNow()
                self.highlighter.parseAndHighlightNow()
                self.tableOfContents = self.renderer.tableOfContents()
            }
        }
    }
    
    let snippets: [Snippet] = [
        Snippet(content: loremSnippet, tabTrigger: "lorem", scope: nil, description: nil),
        Snippet(content: htmlSnippet, tabTrigger: "html", scope: nil, description: nil),
        Snippet(content: htmlReverseSnippet, tabTrigger: "htmlx", scope: nil, description: nil),
        Snippet(content: LaTeXSnippet, tabTrigger: "sumoveriton", scope: nil, description: nil)
    ]
    
    private var snippetHelper: SnippetTextViewHelper!
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default preferences
        
        preferences.editorBaseFont = NSFont(name: "Helvetica", size: 13.0)
        preferences.editorStyleName = "South Lake" // Tomorrow+ // Mou Fresh Air+
        preferences.editorSyncScrolling = true
        
        preferences.htmlMathJax = true
        preferences.htmlMathJaxInlineDollar = false
        preferences.htmlSyntaxHighlighting = true
        preferences.htmlLineNumbers = true
        preferences.htmlHighlightingThemeName = ""
        preferences.htmlRendersTOC = true
        
        preferences.editorHorizontalInset = 10
        preferences.editorVerticalInset = 10
        
        // Snippets
        
        snippetHelper = SnippetTextViewHelper(textView: editor, snippets: snippets)
        editor.delegate = self // (or in IB)
        
        // MacDown Code
        
        highlighter = HGMarkdownHighlighter(textView: editor, waitInterval: 0.1)
        
        renderer = MPRenderer()
        renderer.rendererFlags = preferences.rendererFlags()
        renderer.dataSource = self
        renderer.delegate = self

//        for (NSString *key in MPEditorPreferencesToObserve())
//        {
//            [defaults addObserver:self forKeyPath:key
//                          options:NSKeyValueObservingOptionNew context:NULL];
//        }
        
        for (key, _) in  MPEditorKeysToObserve {
            editor.addObserver(self, forKeyPath: key, options: .New, context: &MarkdownEditorContext)
        }

        editor.postsFrameChangedNotifications = true;
        preview.frameLoadDelegate = self;
        preview.policyDelegate = self;
        preview.editingDelegate = self;

        let center = NSNotificationCenter.defaultCenter()

        center.addObserver(self, selector: #selector(MarkdownEditor.editorTextDidChange(_:)), name: NSTextDidChangeNotification, object: editor)
        
        center.addObserver(self, selector: #selector(MarkdownEditor.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: NSUserDefaults.standardUserDefaults())
        
        center.addObserver(self, selector: #selector(MarkdownEditor.editorBoundsDidChange(_:)), name: NSViewBoundsDidChangeNotification, object: editor.enclosingScrollView?.contentView)
        
        center.addObserver(self, selector: #selector(MarkdownEditor.editorFrameDidChange(_:)), name: NSViewFrameDidChangeNotification, object: editor)
        
//        center.addObserver(self, selector: Selector("didRequestEditorReload"), name: MPDidRequestEditorSetupNotification, object: nil)
//    
//        center.addObserver(self, selector: Selector("didRequestPreviewReload"), name: MPDidRequestPreviewRenderNotification, object: nil)
     
        
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_9) {
            center.addObserver(self, selector: #selector(MarkdownEditor.previewDidLiveScroll(_:)), name: NSScrollViewDidEndLiveScrollNotification, object: preview.mainFrameEnclosingScrollView)
        }
        
        // TODO: this whole thing may not be necessary
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.setupEditor(nil)
            self.redrawDivider()

            // Taken care of in var data
    
//            if let loadedString = self.initialContents {
//                self.editor.string = loadedString
//                self.initialContents = nil
//                
//                self.renderer.parseAndRenderNow()
//                self.highlighter.parseAndHighlightNow()
//                
//                self.toc = self.renderer.tableOfContents()
//            }
        }
        
        // Load test.md
        
//        do {
//            let path = NSBundle.mainBundle().pathForResource("Test", ofType: "md")!
//            let testMD = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
//            initialContents = testMD
//        } catch {
//            NSLog("Unable to read Test.md")
//        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.renderer.parseAndRenderNow()
        self.highlighter.parseAndHighlightNow()
        self.tableOfContents = self.renderer.tableOfContents()
    }
    
    func willClose() {
        
        preview.stopLoading(nil)
        
        // Reneable window flush, which might still be disabled from webView:didCommitLoadForFrame
        
        if let window = self.preview.window {
            objc_sync_enter(window)
            if window.flushWindowDisabled {
                window.enableFlushWindow()
            }
            objc_sync_exit(window)
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        for (key, _) in  MPEditorKeysToObserve {
            editor.removeObserver(self, forKeyPath: key)
        }
        
        highlighter.deactivate()
        highlighter.targetTextView = nil
        
        renderer.dataSource = nil
        renderer.delegate = nil
        
        snippetHelper.stop()
        
        if let file = source {
            unbindUs("data", toObject: file, withKeyPath: "data")
        }
        
        tableOfContentsInspector?.unbind("tableOfContents")
        unbind("tableOfContentsAnchor")
    }
    
    // MARK: - South Lake Functions
    
    var primaryResponder: NSView {
        return editor
    }
    
    func loadTableOfContentsInspector() {
        guard tableOfContentsInspector == nil else {
            return
        }
        
        tableOfContentsInspector = storyboard!.instantiateControllerWithIdentifier("tableOfContents") as? MarkdownTOCInspector
        
        tableOfContentsInspector!.databaseManager = databaseManager
        tableOfContentsInspector!.searchService = searchService
        
        // Bind the inspectors table of contents to ours
        // Bind our anchor to the inspectors
        
        tableOfContentsInspector!.bind("tableOfContents", toObject: self, withKeyPath: "tableOfContents", options: [:])
        
        bind("tableOfContentsAnchor", toObject: tableOfContentsInspector!, withKeyPath: "tableOfContentsAnchor", options: [:])
    }
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
    
    }
    
    // MARK: - MacDown Functions
    
    func adjustEditorInsets() {
        var x = preferences.editorHorizontalInset
        let y = preferences.editorVerticalInset
        
        if preferences.editorWidthLimited {
            let editorWidth = editor.frame.size.width
            let maxWidth = preferences.editorMaximumWidth
            
            // We tend to expect things in an editor to shift to left a bit. Hence the 0.45 instead of 0.5 (which whould feel a bit too much).
            
            if editorWidth > 2 * x + maxWidth {
                x = (editorWidth - maxWidth) * 0.45
            }
        }
        
        editor.textContainerInset = NSSize(width: x, height: y)
    }
    
    func syncScrollers() {
        guard let previewScrollView = preview.mainFrameEnclosingScrollView,
                  previewDocumentView = previewScrollView.documentView else {
            return
        }
        
        let contentBounds = editor.enclosingScrollView!.contentView.bounds
        let realContentRect: NSRect = editor.contentRect()
        var ratio: CGFloat = 0.0
        
        if realContentRect.size.height > contentBounds.size.height {
            ratio = contentBounds.origin.y /
                (realContentRect.size.height - contentBounds.size.height)
        }

        let previewContentView = previewScrollView.contentView
        var previewContentBounds = previewContentView.bounds
        
        previewContentBounds.origin.y =
            ratio * (previewDocumentView.frame.size.height
                     - previewContentBounds.size.height)
        
        previewContentView.bounds = previewContentBounds
    }
    
    func render() {
        renderer.parseAndRenderLater()
    }
    
    func redrawDivider() {
    
    }
    
    func scaleWebview() {
    
    }
    
    func updateWordCount() {
    
    }
    
    func setupEditor(changedKey: String?) {
        highlighter.deactivate()
        
        if changedKey == nil || changedKey == "extensionFootnotes" {
        
        }
        
        if changedKey == nil
            || changedKey == "editorHorizontalInset"
            || changedKey == "editorVerticalInset"
            || changedKey == "editorWidthLimited"
            || changedKey == "editorMaximumWidth"
            {
            
            adjustEditorInsets()
        }
        
        if changedKey == nil
            || changedKey == "editorBaseFontInfo"
            || changedKey == "editorStyleName"
            || changedKey == "editorLineSpacing" {
            
            let style = NSMutableParagraphStyle()
            style.lineSpacing = preferences.editorLineSpacing
            editor.defaultParagraphStyle = style.copy() as? NSParagraphStyle
            
            let font = preferences.editorBaseFont.copy() as? NSFont
            editor.font = font
            
            editor.textColor = nil
            editor.backgroundColor = NSColor.clearColor()
            
            highlighter.styles = nil
            highlighter.readClearTextStylesFromTextView()
            
            let themeName = self.preferences.editorStyleName.copy() as? String
            
            if themeName != nil {
                let path = MPThemePathForName(themeName)
                let themeString = MPReadFileOfPath(path)
                
                highlighter.applyStylesFromStylesheet(themeString, withErrorHandler: { (_: [AnyObject]!) -> Void in
                    self.preferences.editorStyleName = nil
                })
            }
            
            let layer = CALayer()
            layer.backgroundColor = editor.backgroundColor.CGColor
            editorContainer.layer = layer
        }
        
        if changedKey == "editorBaseFontInfo" {
            scaleWebview()
        }
        
        if changedKey == nil || changedKey == "editorShowWordCount" {
        
        }
        
        if changedKey == nil || changedKey == "editorScrollsPastEnd" {
        
        }
        
        if changedKey == nil {
        
        }
        
        if changedKey == nil || changedKey == "editorOnRight" {
        
        }
        
        highlighter.activate()
        editor.automaticLinkDetectionEnabled = false
    }
    
    // MARK: - Notification Handlers
    
    func editorTextDidChange(notification: NSNotification) {
        // Rendering is not necessary, handled in data.didSet
    }

    func userDefaultsDidChange(notification: NSNotification) {
        // TODO
    }
   
    func editorFrameDidChange(notification: NSNotification) {
        if preferences.editorWidthLimited {
            adjustEditorInsets()
        }
    }

    func editorBoundsDidChange(notification: NSNotification) {
        if !shouldHandleBoundsChange {
            return
        }
        
        if preferences.editorSyncScrolling {
            objc_sync_enter(self)
            shouldHandleBoundsChange = false
            syncScrollers()
            shouldHandleBoundsChange = true
            objc_sync_exit(self)
        }
    }

    func didRequestEditorReload(notification: NSNotification) {
        // TODO
    }
   
    func didRequestPreviewReload(notification: NSNotification) {
        render()
    }
    
    func previewDidLiveScroll(notification: NSNotification) {
        guard let contentView = preview.mainFrameEnclosingScrollView?.contentView else {
            return
        }
        
        lastPreviewScrollTop = contentView.bounds.origin.y
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch object {
        case _ as MPEditorView:
            if !highlighter.isActive {
                return
            }
            // TODO
        case _ as NSUserDefaults:
            if highlighter.isActive {
                setupEditor(keyPath!)
            }
            redrawDivider()
        default:
            break
        }
    }
    
    // MARK: - IBAction Editing
    
    @IBAction func convertToH1(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(1)
    }
    
    @IBAction func convertToH2(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(2)
    }
    
    @IBAction func convertToH3(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(3)
    }
    
    @IBAction func convertToH4(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(4)
    }
    
    @IBAction func convertToH5(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(5)
    }
    
    @IBAction func convertToH6(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(6)
    }
    
    @IBAction func convertToParagraph(sender: AnyObject?) {
        editor.makeHeaderForSelectedLinesWithLevel(0)
    }
    
    @IBAction func toggleStrong(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("**", suffix: "**")
    }
    
    @IBAction func toggleEmphasis(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("*", suffix: "*")
    }
    
    @IBAction func toggleInlineCode(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("`", suffix: "`")
    }
    
    @IBAction func toggleStrikethrough(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("~~", suffix: "~~")
    }
    
    @IBAction func toggleUnderline(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("_", suffix: "_")
    }
    
    @IBAction func toggleHighlight(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("==", suffix: "==")
    }
    
    @IBAction func toggleComment(sender: AnyObject?) {
        editor.toggleForMarkupPrefix("<!--", suffix: "-->")
    }
    
    @IBAction func toggleLink(sender: AnyObject?) {
        if editor.toggleForMarkupPrefix("[", suffix: "]()") {
            let range = editor.selectedRange()
            let location = range.location + range.length + 2
            editor.setSelectedRange(NSMakeRange(location, 0))
        }
    }
    
    @IBAction func toggleImage(sender: AnyObject?) {
        if editor.toggleForMarkupPrefix("![", suffix: "]()") {
            let range = editor.selectedRange()
            let location = range.location + range.length + 2
            editor.setSelectedRange(NSMakeRange(location, 0))
        }
    }
    
    @IBAction func toggleUnorderedList(sender: AnyObject?) {
        editor.toggleBlockWithPattern("^[\\*\\+-] \\S", prefix: "* ")
    }
    
    @IBAction func toggleBlockquote(sender: AnyObject?) {
        editor.toggleBlockWithPattern("^> \\S", prefix: "> ")
    }
    
    @IBAction override func indent(sender: AnyObject?) {
        let padding = preferences.editorConvertTabs ? "    " : "\t"
        editor.indentSelectedLinesWithPadding(padding)
    }
    
    @IBAction func unindent(sender: AnyObject?) {
        editor.unindentSelectedLines()
    }
    
    @IBAction func insertNewParagraph(sender: AnyObject?) {
        guard let content = editor.string else {
            return
        }
        
        let range = editor.selectedRange()
        let location = range.location
        let length = range.length
        
        let newlineBefore = (content as NSString).locationOfFirstNewlineBefore(UInt(location))
        let newlineAfter = (content as NSString).locationOfFirstNewlineAfter(UInt(location+length-1))
        
        // If we are on an empty line, treat as normal return key; otherwise insert two newlines
        
        if location == newlineBefore + 1 && UInt(location) == newlineAfter {
            editor.insertNewline(self)
        } else {
            editor.insertText("\n\n")
        }
    }
    
}

// MARK: - NSTextViewDelegate

extension MarkdownEditor: NSTextViewDelegate {
    
    func textView(textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        // Return true to indicate that I handled the command, false otherwise
        let range = textView.selectedRange()
        
        switch commandSelector {
        case #selector(NSResponder.insertTab(_:)):
            return snippetHelper.handleTab(range, forward: true)
        case #selector(NSResponder.insertBacktab(_:)):
            return snippetHelper.handleTab(range, forward: false)
        default:
            return false
        }
    }
    
}

// MARK: - WebFrameLoadDelegate

extension MarkdownEditor: WebFrameLoadDelegate {
    
    var previewLoadingCompletionHandler: (() -> Void) {
        return { () -> Void in
            if let window = self.preview.window {
                objc_sync_enter(window)
                if window.flushWindowDisabled {
                    window.enableFlushWindow()
                }
                objc_sync_exit(window)
            }
            
            self.scaleWebview()
            
            if self.preferences.editorSyncScrolling {
                self.syncScrollers()
            } else {
                let contentView = self.preview.mainFrameEnclosingScrollView!.contentView
                var bounds = contentView.bounds
                
                bounds.origin.y = self.lastPreviewScrollTop
                contentView.bounds = bounds
            }
        }
    }
    
    func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        guard sender.windowScriptObject as WebScriptObject? != nil else {
            return
        }
        
        if let window = sender.window {
            objc_sync_enter(window)
            if !window.flushWindowDisabled {
                window.disableFlushWindow()
            }
            objc_sync_exit(window)
        }
        
        // If MathJax is off, the on-completion callback will be invoked directly when loading is done (in -webView:didFinishLoadForFrame:).
        
        if preferences.htmlMathJax {
            
            let listener = MPMathJaxListener()
            listener.addCallback(previewLoadingCompletionHandler, forKey: "End")
            sender.windowScriptObject.setValue(listener, forKey: "MathJaxListener")
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        // If MathJax is on, the on-completion callback will be invoked by the JavaScript handler injected in -webView:didCommitLoadForFrame:.
        
        if !preferences.htmlMathJax {
            let callback = previewLoadingCompletionHandler
            let queue = NSOperationQueue.mainQueue()
            queue.addOperationWithBlock(callback)
        }
        
        // self.previewReady = true
        
        if preferences.editorShowWordCount {
            updateWordCount()
        }
    }
    
    func webView(sender: WebView!, didFailLoadWithError error: NSError!, forFrame frame: WebFrame!) {
        webView(sender, didFinishLoadForFrame: frame)
    }
}

// MARK: - WebPolicyDelegate

extension MarkdownEditor: WebPolicyDelegate {

}

// MARK: - WebEditingDelegate

extension MarkdownEditor: WebEditingDelegate {
    
    override func webView(webView: WebView!, doCommandBySelector selector: Selector) -> Bool {
        if selector == #selector(NSText.copy(_:)) {
            let html = webView.selectedDOMRange.markupString
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                let pb = NSPasteboard.generalPasteboard()
                if pb.stringForType("public.html") == nil {
                    pb.setString(html, forType: "public.html")
                }
            })
        }
        return false
    }
}

// MARK: - WebUIDelegate

extension MarkdownEditor: WebUIDelegate {
    
    func webView(webView: WebView!, dragDestinationActionMaskForDraggingInfo draggingInfo: NSDraggingInfo!) -> Int {
        return Int(WebDragDestinationAction.None.rawValue)
    }
}

// MARK: - MPRendererDataSource

extension MarkdownEditor: MPRendererDataSource {

    func rendererMarkdown(renderer: MPRenderer!) -> String! {
        return editor.string
    }

    func rendererHTMLTitle(renderer: MPRenderer!) -> String! {
        return "Title"
    }

}

// MARK: - MPRendererDelegate

extension MarkdownEditor: MPRendererDelegate {
    
    func rendererExtensions(renderer: MPRenderer!) -> Int32 {
        return preferences.extensionFlags()
    }
    
    func rendererHasSmartyPants(renderer: MPRenderer!) -> Bool {
        return preferences.extensionSmartyPants
    }
    
    func rendererRendersTOC(renderer: MPRenderer!) -> Bool {
        return preferences.htmlRendersTOC
    }
    
    func rendererStyleName(renderer: MPRenderer!) -> String! {
        return preferences.htmlStyleName
    }
    
    func rendererDetectsFrontMatter(renderer: MPRenderer!) -> Bool {
        return preferences.htmlDetectFrontMatter
    }
    
    func rendererHasSyntaxHighlighting(renderer: MPRenderer!) -> Bool {
        return preferences.htmlSyntaxHighlighting;
    }
    
    func rendererCodeBlockAccesory(renderer: MPRenderer!) -> MPCodeBlockAccessoryType {
        return MPCodeBlockAccessoryType.None
        //return preferences.htmlCodeBlockAccessory
    }
    
    func rendererHasMathJax(renderer: MPRenderer!) -> Bool {
        return preferences.htmlMathJax;
    }
    
    func rendererHighlightingThemeName(renderer: MPRenderer!) -> String! {
        return preferences.htmlHighlightingThemeName;
    }
    
    func renderer(renderer: MPRenderer!, didProduceHTMLOutput html: String!) {
        
        if printing {
            return
        }

        // Delayed copying for -copyHtml.
        if (copying) {
            copying = false
            
            NSPasteboard.generalPasteboard().clearContents()
            NSPasteboard.generalPasteboard().writeObjects([renderer.currentHtml()])
        }
        

        let baseURL = NSBundle.mainBundle().bundleURL
        preview.mainFrame.loadHTMLString(html, baseURL: baseURL)

        // NSURL *baseUrl = self.fileURL;
        // if (!baseUrl)   // Unsaved doument; just use the default URL.baseUrl = self.preferences.htmlDefaultDirectoryUrl;
        // [self.preview.mainFrame loadHTMLString:html baseURL:baseUrl];
        // self.manualRender = self.preferences.markdownManualRender;
        //self.currentBaseUrl = baseUrl;
    }
}


// MARK: - HoedownExtensions

struct HoedownExtensions: OptionSetType {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    
    static let NONE =                                   HoedownExtensions(rawValue: 0)
    
    /* block-level extensions */
    static let HOEDOWN_EXT_TABLES =                     HoedownExtensions(rawValue: 1 << 0)
    static let HOEDOWN_EXT_FENCED_CODE =                HoedownExtensions(rawValue: 1 << 1)
    static let HOEDOWN_EXT_FOOTNOTES =                  HoedownExtensions(rawValue: 1 << 2)
    
    /* span-level extensions */
    static let HOEDOWN_EXT_AUTOLINK =                   HoedownExtensions(rawValue: 1 << 3)
    static let HOEDOWN_EXT_STRIKETHROUGH =              HoedownExtensions(rawValue: 1 << 4)
    static let HOEDOWN_EXT_UNDERLINE =                  HoedownExtensions(rawValue: 1 << 5)
    static let HOEDOWN_EXT_HIGHLIGHT =                  HoedownExtensions(rawValue: 1 << 6)
    static let HOEDOWN_EXT_QUOTE =                      HoedownExtensions(rawValue: 1 << 7)
    static let HOEDOWN_EXT_SUPERSCRIPT =                HoedownExtensions(rawValue: 1 << 8)
    static let HOEDOWN_EXT_MATH =                       HoedownExtensions(rawValue: 1 << 9)
    
    // skip 1 << 10
    
    /* other flags */
    static let HOEDOWN_EXT_NO_INTRA_EMPHASIS =          HoedownExtensions(rawValue: 1 << 11)
    static let HOEDOWN_EXT_SPACE_HEADERS =              HoedownExtensions(rawValue: 1 << 12)
    static let HOEDOWN_EXT_MATH_EXPLICIT =              HoedownExtensions(rawValue: 1 << 13)
    
    /* negative flags */
    static let HOEDOWN_EXT_DISABLE_INDENTED_CODE =      HoedownExtensions(rawValue: 1 << 14)
    
    /* additional extensions */
    static let HOEDOWN_HTML_USE_TASK_LIST =             HoedownExtensions(rawValue: 1 << 4)
    static let HOEDOWN_HTML_BLOCKCODE_LINE_NUMBERS =    HoedownExtensions(rawValue: 1 << 5)
    static let HOEDOWN_HTML_BLOCKCODE_INFORMATION =     HoedownExtensions(rawValue: 1 << 6)
    
    static let HOEDOWN_HTML_SKIP_HTML =                 HoedownExtensions(rawValue: 1 << 0)
    static let HOEDOWN_HTML_ESCAPE =                    HoedownExtensions(rawValue: 1 << 1)
    static let HOEDOWN_HTML_HARD_WRAP =                 HoedownExtensions(rawValue: 1 << 2)
    static let HOEDOWN_HTML_USE_XHTML =                 HoedownExtensions(rawValue: 1 << 3)
}

// MARK: - MPPreferences

extension MPPreferences {
    func extensionFlags() -> Int32 {
        var flags: HoedownExtensions = []
        if (extensionAutolink) {
            flags.insert(.HOEDOWN_EXT_AUTOLINK)
        }
        if (extensionFencedCode) {
            flags.insert(.HOEDOWN_EXT_FENCED_CODE)
        }
        if (extensionFootnotes) {
            flags.insert(.HOEDOWN_EXT_FOOTNOTES)
        }
        if (extensionHighlight) {
            flags.insert(.HOEDOWN_EXT_HIGHLIGHT)
        }
        if (!extensionIntraEmphasis) {
            flags.insert(.HOEDOWN_EXT_NO_INTRA_EMPHASIS)
        }
        if (extensionQuote) {
            flags.insert(.HOEDOWN_EXT_QUOTE)
        }
        if (extensionStrikethough) {
            flags.insert(.HOEDOWN_EXT_STRIKETHROUGH)
        }
        if (extensionSuperscript) {
            flags.insert(.HOEDOWN_EXT_SUPERSCRIPT)
        }
        if (extensionTables) {
            flags.insert(.HOEDOWN_EXT_TABLES)
        }
        if (extensionUnderline) {
            flags.insert(.HOEDOWN_EXT_UNDERLINE)
        }
        if (htmlMathJax) {
            flags.insert(.HOEDOWN_EXT_MATH)
        }
        if (htmlMathJaxInlineDollar) {
            flags.insert(.HOEDOWN_EXT_MATH_EXPLICIT)
        }
        return Int32(flags.rawValue);
    }

    func rendererFlags() -> Int32 {
        var flags: HoedownExtensions = []
        
        if (htmlTaskList) {
            flags.insert(.HOEDOWN_HTML_USE_TASK_LIST)
        }
        if (htmlLineNumbers) {
            flags.insert(.HOEDOWN_HTML_BLOCKCODE_LINE_NUMBERS)
        }
        if (self.htmlHardWrap) {
            flags.insert(.HOEDOWN_HTML_HARD_WRAP)
        }
//        if (self.htmlCodeBlockAccessory == MPCodeBlockAccessoryCustom) {
//            flags.insert(.HOEDOWN_HTML_BLOCKCODE_INFORMATION)
//        }
        
        return Int32(flags.rawValue);
    }
}
