//
//  PrefGeneralViewController.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 19/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Cocoa
import MASPreferences
import ServiceManagement

class PrefGeneralViewController: NSViewController, NSTextFieldDelegate, MASPreferencesViewController {
    let Prefs = PrefManager.shared
    var viewIdentifier: String = "PrefGeneralView"
    var toolbarItemImage: NSImage? {
        get { return NSImage(named: .preferencesGeneral)! }
    }
    var toolbarItemLabel: String? {
        get { return "General" }
    }
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefGeneralView") }
    }
    
    var appDelegate: AppDelegate!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var launchAtLogin: NSButton!
    let launcherAppIdentifier = "me.choco.FlixDNS-Login-Helper"
    
    @objc
    dynamic private var startAtLogin : Bool {
        get {
            guard let jobDicts = SMCopyAllJobDictionaries( kSMDomainUserLaunchd ).takeRetainedValue() as? [[String:Any]] else { return false }
            return jobDicts.first(where: { $0["Label"] as! String == launcherAppIdentifier }) != nil
        } set {
            if !SMLoginItemSetEnabled(launcherAppIdentifier as CFString, newValue) {
                NSLog("SMLoginItemSetEnabled failed")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = NSApplication.shared.delegate as! AppDelegate
        emailTextField.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateFromPrefs()
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        Prefs.userDefaults.set(emailTextField.stringValue, forKey: Keys.accountEmail)
    }
    
    func updateFromPrefs() {
        emailTextField.stringValue = Prefs.userDefaults.string(forKey: Keys.accountEmail)!
        launchAtLogin.state = startAtLogin ? .on : .off
    }
    
    @IBAction func launchAtLoginClicked(_ sender: NSButton) {
        startAtLogin = sender.state == .on
    }
}
