//
//  PrefAboutViewController.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 19/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Cocoa
import MASPreferences

class PrefAboutViewController: NSViewController, MASPreferencesViewController {
    var viewIdentifier: String = "PrefAboutView"
    var toolbarItemImage: NSImage? {
        get { return NSImage(named: .info)! }
    }
    var toolbarItemLabel: String? {
        get { return "About" }
    }
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefAboutView") }
    }
    
    @IBOutlet weak var versionLabel: NSTextField!
    private var version : String = ""
    private var buildNumber : String = ""
    private var gitShortHash : String = ""
    private var showingGitShortHash : Bool = false
    @objc dynamic let updateManager = UpdateManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let versionObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let buildNumberObject = Bundle.main.infoDictionary?["CFBundleVersion"]
        let gitShortHashObject = Bundle.main.infoDictionary?["GitShortHash"]
        version = versionObject as? String ?? ""
        buildNumber = buildNumberObject as? String ?? ""
        gitShortHash = gitShortHashObject as? String ?? ""
        versionLabel.stringValue = "\(version) (\(buildNumber))"
    }
    
    @IBAction func versionLabelClicked(_ sender: NSButton) {
        versionLabel.stringValue = showingGitShortHash ?
            "\(version) (\(buildNumber))" : "\(version) (\(gitShortHash))"
        showingGitShortHash = !showingGitShortHash
    }
    
    @IBAction func checkUpdateClicked(_ sender: NSButton) {
        updateManager.checkForUpdates()
    }
    
    @IBAction func visitWebsiteClicked(_ sender: NSButton) {
        guard let url = URL(string: "https://github.com/choco/FlixDNS") else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func submitFeedbackClicked(_ sender: NSButton) {
        guard let url = URL(string: "mailto:dev@choco.me?subject=FlixDNS%20Feedback") else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func creditsButtonClicked(_ sender: Any) {
        guard let path = Bundle.main.path(forResource: "credits", ofType: "rtf") else { return }
        NSWorkspace.shared.openFile(path)
    }
}

class LinkButton: NSButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func resetCursorRects() {
        addCursorRect(self.bounds, cursor: .pointingHand)
    }
}
