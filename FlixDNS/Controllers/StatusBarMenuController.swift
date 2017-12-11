//
//  StatusBarMenuController.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 28/04/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Cocoa
import FlagKit

enum ItemStatus {
    case Enabled
    case Disabled
    case Busy
    case Updating
    case Unknown
}

class StatusBarMenuController: NSWindowController, NSMenuDelegate {
    override var windowNibName: NSNib.Name {
        get { return NSNib.Name("StatusBarMenu") }
    }
    @IBOutlet weak var statusbarMenu: NSMenu!
    @IBOutlet weak var ipItem: NSMenuItem!
    @IBOutlet weak var dnsItem: NSMenuItem!
    @IBOutlet weak var regionItem: NSMenuItem!
    @IBOutlet weak var regionsMenu: NSMenu!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let icon = NSImage(named: NSImage.Name(rawValue: "nflxstatus"))
    let icondark = NSImage(named: NSImage.Name(rawValue: "nflxstatus-dark"))
    let enabledImage = NSImage(named:NSImage.Name(rawValue: "NSStatusAvailable"))!
    let disabledImage = NSImage(named:NSImage.Name(rawValue: "NSStatusUnavailable"))!
    let loadingImage = NSImage(named:NSImage.Name(rawValue: "NSStatusPartiallyAvailable"))!
    var availableRegions: [Region] = []
    var selectedRegionIndex: Int = -1
    var currentIP: String = ""
    var API: UnblockUsAPI!
    let Prefs = PrefManager.shared
    var isProfileUpdating = false
    var isRegionUpdating = false
    
    override func windowDidLoad() {
        statusbarMenu.delegate = self
        statusItem.menu = statusbarMenu
        
        self.updateStatusItemIcon()
        DistributedNotificationCenter.default()
            .addObserver(forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
                         object: nil,
                         queue: OperationQueue.main) { (note) in
                            self.updateStatusItemIcon()
        }
        
        API = UnblockUsAPI(auth_email: Prefs.userDefaults.string(forKey: Keys.accountEmail)!)
        Prefs.userDefaults.addObserver(self, forKeyPath: Keys.accountEmail, options: .new, context: nil)
        
        setMenuItem(item: ipItem, status: .Busy)
        setMenuItem(item: dnsItem, status: .Busy)
        setMenuItem(item: regionItem, status: .Busy)
        regionItem.isEnabled = false
        
        updateProfile()
        updateAvailableRegions {
            self.updateCurrentRegion()
        }
    }
    
    @objc func regionSelected(_ sender: NSMenuItem) {
        isRegionUpdating = true
        let newRegion: Region = availableRegions[sender.tag]
        let oldRegion: Region = availableRegions[selectedRegionIndex]
        DispatchQueue.main.async {
            for item in self.regionsMenu.items {
                item.isEnabled = false
            }
        }

        self.setMenuItem(item: self.regionItem, status: .Updating)
        API.setRegion(newRegion, success: { success in
            if success {
                DispatchQueue.main.async {
                    self.regionsMenu.item(withTag: self.availableRegions.index(of: oldRegion)!)?.state = .off
                    sender.state = .on
                }
                self.selectedRegionIndex = sender.tag
                self.setMenuItem(item: self.regionItem, status: newRegion.code == "XX" ? .Disabled : .Enabled)
                let appDelegate = NSApplication.shared.delegate as? AppDelegate
                if (appDelegate?.privilegedHelperInstalled)! {
                    let helper = appDelegate?.helperConnection()?.remoteObjectProxyWithErrorHandler { error in
                        NSLog("XPC Privileged Helper comunication failed")
                        } as! PrivilegedHelperProtocol
                    helper.flushDNSCache(reply: {exit_code, output in
                        if exit_code != 0 {
                            NSLog("DNS cache flush failed")
                        }
                    })
                }
            }
            DispatchQueue.main.async {
                for item in self.regionsMenu.items {
                    item.isEnabled = true
                }
            }
            self.isRegionUpdating = false
        }, failed: {
            self.setMenuItem(item: self.regionItem, status: .Busy)
            self.isRegionUpdating = false
        })
    }
    
    @IBAction func updateIP(_ sender: NSMenuItem) {
        setMenuItem(item: ipItem, status: .Updating)
        API.updateIP({ success in
            if success {
                self.setMenuItem(item: self.ipItem, status: .Enabled)
            } else {
                self.setMenuItem(item: self.ipItem, status: .Disabled)
            }
        }, failed: {
            self.setMenuItem(item: self.ipItem, status: .Busy)
        })
    }
    
    @IBAction func updateDNS(_ sender: NSMenuItem) {
        setMenuItem(item: dnsItem, status: .Updating)
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        if (appDelegate?.privilegedHelperInstalled)! {
            let helper = appDelegate?.helperConnection()?.remoteObjectProxyWithErrorHandler { error in
                NSLog("XPC Privileged Helper comunication failed")
                self.setMenuItem(item: self.dnsItem, status: .Disabled)
                } as! PrivilegedHelperProtocol
            helper.installSmartDNSConf(UnblockUsAPI.SmartDNSConf) { result, error_msg in
                                    if result {
                                        NSLog("Resolver DNS directory created successfuly")
                                        helper.flushDNSCache(reply: {exit_code, output in
                                            if exit_code != 0 {
                                                NSLog("DNS cache flush failed")
                                            }
                                        })
                                        self.isProfileUpdating = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                            self.isProfileUpdating = false
                                            self.updateProfile()
                                        }
                                    } else {
                                        NSLog("SmartDNSConfiguration installation failed: \(error_msg)")
                                        self.setMenuItem(item: self.dnsItem, status: .Disabled)
                                    }
            }
        }
    }
    
    func updateProfile() {
        if(!isProfileUpdating) {
            isProfileUpdating = true
            API.fetchProfile( { profile in
                self.currentIP = profile.IP
                if profile.ip_changed {
                    self.setMenuItem(item: self.ipItem, status: .Disabled)
                } else {
                    self.setMenuItem(item: self.ipItem, status: .Enabled)
                }
                
                if profile.dns {
                    self.setMenuItem(item: self.dnsItem, status: .Enabled)
                } else {
                    self.setMenuItem(item: self.dnsItem, status: .Disabled)
                }
                self.isProfileUpdating = false
            }, failed: {
                self.setMenuItem(item: self.ipItem, status: .Busy)
                self.setMenuItem(item: self.dnsItem, status: .Busy)
                self.isProfileUpdating = false
            })
        }
    }
    
    func updateCurrentRegion() {
        if(!isRegionUpdating) {
            isRegionUpdating = true
            self.API.getCurrentRegion( { region in
                if(region.code != "NA") {
                    self.selectedRegionIndex = self.availableRegions.index(of: region)!
                    self.setMenuItem(item: self.regionItem, status: region.code == "XX" ? .Disabled : .Enabled)
                    DispatchQueue.main.async {
                        for item in self.regionsMenu.items {
                            item.isEnabled = true
                            item.state = .off
                        }
                        self.regionsMenu.item(withTag: self.selectedRegionIndex)?.state = .on
                    }
                } else {
                    self.selectedRegionIndex = -1
                    self.setMenuItem(item: self.regionItem, status: .Unknown)
                    DispatchQueue.main.async {
                        for item in self.regionsMenu.items {
                            item.isEnabled = false
                            item.state = .off
                        }
                    }
                }
                self.isRegionUpdating = false

            }, failed: {
                self.selectedRegionIndex = -1
                self.setMenuItem(item: self.regionItem, status: .Busy)
                DispatchQueue.main.async {
                    for item in self.regionsMenu.items {
                        item.isEnabled = false
                        item.state = .off
                    }
                }
                self.isRegionUpdating = false
            })
            
        }
    }
    
    func updateAvailableRegions(onSuccess: @escaping () -> Void) {
        API.fetchAvailableRegions( { regions in
            self.availableRegions = regions.reversed()
            DispatchQueue.main.async {
                for (index, region) in self.availableRegions.enumerated() {
                    let item = NSMenuItem(title: region.countryName(), action: #selector(self.regionSelected(_:)), keyEquivalent: "")
                    item.tag = index
                    item.target = self
                    item.isEnabled = false
                    if let regionImage = Flag(countryCode: region.code) {
                        item.image = regionImage.originalImage
                    }
                    if (region.code == "XX") {
                        self.regionsMenu.addItem(item)
                    } else {
                        self.regionsMenu.insertItem(item, at: 0)
                    }
                }
                self.regionItem.isEnabled = true
            }
            onSuccess()
        }, failed: {
            
        })
    }
    
    func setMenuItem(item: NSMenuItem, status: ItemStatus) {
        let itemTitle : String
        let itemImage : NSImage
        let itemEnabled : Bool
        switch item {
        case ipItem:
            switch status {
            case .Busy:
                itemTitle = "  Checking IP..."
                itemImage = loadingImage
                itemEnabled = false
            case .Enabled:
                itemTitle = "  IP: \(currentIP)"
                itemImage = enabledImage
                itemEnabled = false
            case .Disabled:
                itemTitle = "  Update IP"
                itemImage = disabledImage
                itemEnabled = true
            case .Updating:
                itemTitle = "  Updating IP..."
                itemImage = loadingImage
                itemEnabled = false
            case .Unknown:
                itemTitle = "  Unknown IP"
                itemImage = loadingImage
                itemEnabled = false
            }
        case dnsItem:
            switch status {
            case .Busy:
                itemTitle = "  Checking DNS..."
                itemImage = loadingImage
                itemEnabled = false
            case .Enabled:
                itemTitle = "  Unblock-Us DNS"
                itemImage = enabledImage
                itemEnabled = false
            case .Disabled:
                itemTitle = "  Update DNS"
                itemImage = disabledImage
                itemEnabled = true
            case .Updating:
                itemTitle = "  Updating DNS..."
                itemImage = loadingImage
                itemEnabled = false
            case .Unknown:
                itemTitle = "  Unknown DNS"
                itemImage = loadingImage
                itemEnabled = true
            }
        case regionItem:
            switch status {
            case .Busy:
                itemTitle = "  Checking Region..."
                itemImage = loadingImage
                itemEnabled = true
            case .Enabled:
                let region = availableRegions[selectedRegionIndex]
                itemTitle = " \(region.countryName())"
                if let regionImage = Flag(countryCode: region.code) {
                    itemImage = regionImage.originalImage
                } else {
                    itemImage = enabledImage
                }
                itemEnabled = true
            case .Disabled:
                itemTitle = " Disabled"
                itemImage = disabledImage
                itemEnabled = true
            case .Updating:
                itemTitle = "  Updating Region..."
                itemImage = loadingImage
                itemEnabled = true
            case .Unknown:
                itemTitle = "  Login Failed"
                itemImage = loadingImage
                itemEnabled = false
            }
        default:
            itemTitle = "Unknown title"
            itemImage = disabledImage
            itemEnabled = false

            NSLog("Unkwon menu item")
        }
        DispatchQueue.main.async {
            item.title = itemTitle
            item.image = itemImage
            item.isEnabled = itemEnabled
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath! {
        case Keys.accountEmail:
            API.auth_email = Prefs.userDefaults.string(forKey: Keys.accountEmail)
            updateProfile()
            updateCurrentRegion()
        default:
            NSLog("Unknown preference changed")
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        updateProfile()
        updateCurrentRegion()
    }
    
    func menuDidClose(_ menu: NSMenu) {
    }
    
    func updateStatusItemIcon() {
        if (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark") {
            statusItem.image = icondark
            statusItem.alternateImage = icondark
        } else {
            statusItem.image = icon
            statusItem.alternateImage = icondark
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.preferenceWindowController.showWindow(sender)
    }
}
