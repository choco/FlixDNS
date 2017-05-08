//
//  StatusBarMenuController.swift
//  Keenow
//
//  Created by Enrico Ghirardi on 28/04/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Cocoa

class StatusBarMenuController: NSObject {
    @IBOutlet weak var statusbarMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let icon = NSImage(named: "nflxstatus")
    let icondark = NSImage(named: "nflxstatus-dark")
    
    override func awakeFromNib() {
        statusItem.menu = statusbarMenu
        self.updateStatusItemIcon()
        statusItem.menu = statusbarMenu
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(themeChanged(_:)),
                                                            name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
                                                            object: nil)

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
    
    func themeChanged(_ sender: NSNotification) {
        self.updateStatusItemIcon()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}
