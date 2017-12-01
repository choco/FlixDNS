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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let versionObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let buildNumberObject = Bundle.main.infoDictionary?["CFBundleVersion"]
        let version = versionObject as? String ?? ""
        let buildNumber = buildNumberObject as? String ?? ""
        versionLabel.stringValue = "\(version) (\(buildNumber))"
    }
    
    @IBAction func checkUpdateClicked(_ sender: NSButton) {
    }
    
    @IBAction func visitWebsiteClicked(_ sender: NSButton) {
        guard let url = URL(string: "https://github.com/choco/FlixDNS") else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func submitFeedbackClicked(_ sender: NSButton) {
        NSLog("HERE WE ARE!")
        guard let url = URL(string: "mailto:dev@choco.me?subject=FlixDNS%20Feedback") else {
            NSLog("HERE WE ARE! UFFI")
            return }
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
