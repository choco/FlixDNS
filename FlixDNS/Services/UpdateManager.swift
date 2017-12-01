//
//  UpdateManager.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 30/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation
import SparkleCore

class UpdateManager : NSObject, SPUUpdaterDelegate {
    private var updater : SPUUpdater?
    private var userDriver : FDNSUpdaterUserDriver?
    private var startedUpdater : Bool = false
    
    static let shared = UpdateManager()
    
    private override init() {
        super.init()
        userDriver = FDNSUpdaterUserDriver()
        updater = SPUUpdater(hostBundle: Bundle.main,
                             applicationBundle: Bundle.main,
                             userDriver: userDriver!,
                             delegate: self)
        updater?.automaticallyChecksForUpdates = true
        do {
            try updater!.start()
            startedUpdater = true
        } catch {
            NSLog("Update error \(error)")
        }
    }
    
    var canCheckForUpdates: Bool {
        get {
            return startedUpdater && (userDriver?.canCheckForUpdates)!
        }
    }
    
    func updater(_ updater: SPUUpdater, shouldAllowInstallerInteractionFor updateCheck: SPUUpdateCheck) -> Bool {
        switch updateCheck {
        case .userInitiated:
            return true
        case .backgroundScheduled:
            return false
        }
    }
    
    func updaterShouldDownloadReleaseNotes(_ updater: SPUUpdater) -> Bool {
        return false
    }
    
    func checkForUpdates() {
        if startedUpdater {
            updater?.checkForUpdates()
        }
    }
}
