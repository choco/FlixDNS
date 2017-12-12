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
    
    @IBAction func reinstallSmartDNSConfClicked(_ sender: NSButton) {
        let helper = appDelegate?.helperConnection()?.remoteObjectProxyWithErrorHandler { error in
            NSLog("XPC Privileged Helper comunication failed")
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
            } as! PrivilegedHelperProtocol
        sender.isEnabled = false
        guard let jobDicts = SMCopyAllJobDictionaries( kSMDomainSystemLaunchd ).takeRetainedValue() as? [[String:Any]] else { return }
        let running = jobDicts.first(where: { $0["Label"] as! String == PrivilegedHelperConstants.machServiceName }) != nil
        NSLog("IS running \(running)")
        helper.installSmartDNSConf(revision: UnblockUsAPI.SmartDNSConf.revision,
                                   dns: UnblockUsAPI.SmartDNSConf.DNS,
                                   domains: UnblockUsAPI.SmartDNSConf.domains) { result, error_msg in
                                    if result {
                                        DispatchQueue.main.async {
                                            let alert: NSAlert = NSAlert()
                                            alert.messageText = "SmartDNS Configuration was reinstalled successfully"
                                            alert.informativeText = "The domains and corresponding DNS have been correctly reinstalled"
                                            alert.alertStyle = .informational
                                            alert.addButton(withTitle: "OK")
                                            alert.runModal()
                                        }
                                        helper.flushDNSCache(reply: {exit_code, output in
                                            if exit_code != 0 {
                                                NSLog("DNS cache flush failed")
                                            }
                                        })
                                    } else {
                                        DispatchQueue.main.async {
                                            let alert: NSAlert = NSAlert()
                                            alert.messageText = "SmartDNS Configuration reinstallation failed"
                                            alert.informativeText = "FlixDNS wasn't able to reinstall the SmartDNS configuration"
                                            alert.alertStyle = .critical
                                            alert.addButton(withTitle: "OK")
                                            alert.runModal()
                                        }
                                        NSLog("SmartDNSConfiguration reinstallation failed: \(error_msg)")
                                    }
                                    DispatchQueue.main.async {
                                        sender.isEnabled = true
                                    }
        }
    }
    
    @IBAction func uninstallFlixDNS(_ sender: NSButton) {
        let helper = appDelegate?.helperConnection()?.remoteObjectProxyWithErrorHandler { error in
            NSLog("XPC Privileged Helper comunication failed")
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
            } as! PrivilegedHelperProtocol
        sender.isEnabled = false
        helper.uninstallHelper { result, err_msg in
            if result {
                DispatchQueue.main.asyncAfter(deadline: .now() + PrivilegedHelperConstants.shutDownTime*2) {
                    guard let jobDicts = SMCopyAllJobDictionaries( kSMDomainSystemLaunchd ).takeRetainedValue() as? [[String:Any]] else { return }
                    let running = jobDicts.first(where: { $0["Label"] as! String == PrivilegedHelperConstants.machServiceName }) != nil
                    if running {
                        self.uninstallationFailedAlert(sender, err_msg: err_msg)
                    } else {
                        let alert: NSAlert = NSAlert()
                        alert.messageText = "FlixDNS uninstallation was successfull"
                        alert.informativeText = "The application will now terminate, move the application to the Trash to complete the uninstallation process"
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                        
                        NSApplication.shared.terminate(self)
                    }
                }
            } else {
                self.uninstallationFailedAlert(sender, err_msg: err_msg)
            }
        }
    }
    
    private func uninstallationFailedAlert(_ sender: NSButton, err_msg: String) {
        DispatchQueue.main.async {
            let alert: NSAlert = NSAlert()
            alert.messageText = "FlixDNS uninstallation failed"
            alert.informativeText = "The uninstall process failed, please report the issue to the developer"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            sender.isEnabled = true
        }
        NSLog("Error couldn't uninstall Privileged Helper tool \(err_msg)")
    }
}
