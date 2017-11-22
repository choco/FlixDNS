//
//  AppDelegate.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 28/04/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Cocoa
import MASPreferences
import ServiceManagement

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let Prefs = PrefManager.shared
    var xpcPrivilegedHelperConnection: NSXPCConnection?
    var privilegedHelperInstalled: Bool = false
    
    lazy var preferenceWindowController: PrefWindowController = {
        return PrefWindowController(
            viewControllers: [
                PrefGeneralViewController(),
                PrefAboutViewController()],
            title: "Preferences")
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        shouldInstallHelper {
            installed in
            if !installed {
                if self.installHelper() {
                    self.xpcPrivilegedHelperConnection = nil
                    self.privilegedHelperInstalled = true
                }
            } else {
                self.privilegedHelperInstalled = true
            }
        }
        
        let launcherAppIdentifier = "me.choco.FlixDNS-Login-Helper"
        let runningApps = NSWorkspace.shared.runningApplications
        let startedAtLogin = !runningApps.filter { $0.bundleIdentifier == launcherAppIdentifier }.isEmpty

        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: .killLauncher,
                                                         object: Bundle.main.bundleIdentifier!)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    /*
     Install Helper Functions
     */
    func shouldInstallHelper(callback: @escaping (Bool) -> Void){
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/\(PrivilegedHelperConstants.machServiceName)")
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL!)
        if helperBundleInfo != nil {
            let helperInfo = helperBundleInfo as! [String: AnyObject]
            let helperVersion = helperInfo["CFBundleVersion"] as! String

            let helper = self.helperConnection()?.remoteObjectProxyWithErrorHandler({
                _ in callback(false)
            }) as! PrivilegedHelperProtocol

            helper.getVersion(reply: {
                installedVersion in
                NSLog("Helper: Installed Version => \(installedVersion)")
                callback(helperVersion == installedVersion)
            })
        } else {
            callback(false)
        }
    }
    
    // Uses SMJobBless to install or update the helper tool
    func installHelper() -> Bool {
        var authRef:AuthorizationRef?
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var authRights:AuthorizationRights = AuthorizationRights(count: 1, items:&authItem)
        let authFlags: AuthorizationFlags = [ [], .extendRights, .interactionAllowed, .preAuthorize ]
        
        let status = AuthorizationCreate(&authRights, nil, authFlags, &authRef)
        if (status != errAuthorizationSuccess){
            let error = NSError(domain:NSOSStatusErrorDomain, code:Int(status), userInfo:nil)
            NSLog("Authorization error: \(error)")
            return false
        } else {
            var cfError: Unmanaged<CFError>? = nil
            if !SMJobBless(kSMDomainSystemLaunchd, PrivilegedHelperConstants.machServiceName as CFString, authRef, &cfError) {
                let blessError = cfError!.takeRetainedValue() as Error
                NSLog("Bless Error: \(blessError)")
                return false
            } else {
                NSLog("\(PrivilegedHelperConstants.machServiceName) installed successfully")
                return true
            }
        }
    }

    // There might be issues with this, It doesn't check if the conenction is suspended for example. That might need to be handled.
    func helperConnection() -> NSXPCConnection? {
        if (self.xpcPrivilegedHelperConnection == nil){
            self.xpcPrivilegedHelperConnection = NSXPCConnection(machServiceName:PrivilegedHelperConstants.machServiceName, options:NSXPCConnection.Options.privileged)
            self.xpcPrivilegedHelperConnection!.remoteObjectInterface = NSXPCInterface(with:PrivilegedHelperProtocol.self)
            self.xpcPrivilegedHelperConnection!.invalidationHandler = {
                self.xpcPrivilegedHelperConnection?.invalidationHandler = nil
                OperationQueue.main.addOperation(){
                    self.xpcPrivilegedHelperConnection = nil
                    NSLog("Privileged Helper XPC Connection Invalidated\n")
                }
            }
            self.xpcPrivilegedHelperConnection?.resume()
        }
        return self.xpcPrivilegedHelperConnection
    }

}

