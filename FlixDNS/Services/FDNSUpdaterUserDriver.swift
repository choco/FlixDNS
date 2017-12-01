//
//  FDNSUpdaterUserDriver.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 30/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation
import Cocoa
import SparkleCore

class FDNSUpdaterUserDriver : NSObject, SPUUserDriver {
    
    private let coreComponent = SPUUserDriverCoreComponent()
    private(set) var canCheckForUpdates: Bool = false
    
    func showCanCheck(forUpdates canCheckForUpdates: Bool) {
        self.canCheckForUpdates = canCheckForUpdates
    }
    
    func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
        reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
    }
    
    func showUserInitiatedUpdateCheck(completion updateCheckStatusCompletion: @escaping (SPUUserInitiatedCheckStatus) -> Void) {
        coreComponent.registerUpdateCheckStatusHandler(updateCheckStatusCompletion)
    }
    
    func dismissUserInitiatedUpdateCheck() {
        coreComponent.completeUpdateCheckStatus()
    }
    
    func promptUserInitiatedCheck(userInitiatedCheck: Bool,
                                  informativeText: String,
                                  response: @escaping (SPUUpdateAlertChoice) -> Void)
    {
    }
    
    func showUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUUpdateAlertChoice) -> Void) {
        let informativeText = ""
        promptUserInitiatedCheck(userInitiatedCheck: userInitiated, informativeText: informativeText, response: reply)
    }
    
    func showDownloadedUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUUpdateAlertChoice) -> Void) {
        let informativeText = ""
        promptUserInitiatedCheck(userInitiatedCheck: userInitiated, informativeText: informativeText, response: reply)
    }
    
    func showResumableUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUInstallUpdateStatus) -> Void) {
        if (userInitiated) {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.informativeText = ""
            alert.messageText = ""
            alert.addButton(withTitle: "")
            alert.runModal()
        }
        reply(.dismissUpdateInstallation)
    }
    
    func showInformationalUpdateFound(with appcastItem: SUAppcastItem, userInitiated: Bool, reply: @escaping (SPUInformationalUpdateAlertChoice) -> Void) {
        if userInitiated {
            NSWorkspace.shared.open(appcastItem.infoURL)
        }
        reply(.dismissInformationalNoticeChoice)
    }
    
    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
    }
    
    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
    }
    
    func showUpdateNotFound(acknowledgement: @escaping () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.informativeText = ""
        alert.messageText = ""
        alert.addButton(withTitle: "")
        alert.runModal()
        acknowledgement()
    }
    
    func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        let alert = NSAlert(error: error)
        alert.runModal()
        acknowledgement()
    }
    
    func showDownloadInitiated(completion downloadUpdateStatusCompletion: @escaping (SPUDownloadUpdateStatus) -> Void) {
        coreComponent.registerDownloadStatusHandler(downloadUpdateStatusCompletion)
    }
    
    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
    }
    
    func showDownloadDidReceiveData(ofLength length: UInt64) {
    }
    
    func showDownloadDidStartExtractingUpdate() {
        coreComponent.completeDownloadStatus()
    }
    
    func showExtractionReceivedProgress(_ progress: Double) {
    }
    
    func showReady(toInstallAndRelaunch installUpdateHandler: @escaping (SPUInstallUpdateStatus) -> Void) {
    }
    
    func showInstallingUpdate() {
    }
    
    func showSendingTerminationSignal() {
    }
    
    func showUpdateInstallationDidFinish(acknowledgement: @escaping () -> Void) {
        acknowledgement()
    }
    
    func dismissUpdateInstallation() {
    }
}
