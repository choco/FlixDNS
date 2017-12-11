//
//  PrivilegedHelperService.swift
//  FlixDNS Privileged Helper
//
//  Created by Enrico Ghirardi on 20/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

class PrivilegedHelperService: NSObject, PrivilegedHelperProtocol, NSXPCListenerDelegate{
    private var connections = [NSXPCConnection]()
    private var listener:NSXPCListener
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0
    private let resolverDir = "/etc/resolver"
    private let configurationFile = "FlixDNS_conf"
    
    override init(){
        self.listener = NSXPCListener(machServiceName:PrivilegedHelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }
    
    /*
     Starts the helper tool
     */
    func run(){
        self.listener.resume()
        
        // Kepp the helper running until shouldQuit variable is set to true.
        // This variable is changed to true in the connection invalidation handler in the listener(_ listener:shoudlAcceptNewConnection:) funciton.
        while !shouldQuit {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: shouldQuitCheckInterval))
        }
    }
    
    /*
     Called when the application connects to the helper
     */
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool
    {
        
        // MARK: Here a check should be added to verify the application that is calling the helper
        // For example, checking that the codesigning is equal on the calling binary as this helper.
        let interface = NSXPCInterface(with: PrivilegedHelperProtocol.self)
        let sel = #selector(installSmartDNSConf(_:reply:))
        let acceptedClassesSet = interface.classes(for: sel, argumentIndex: 0, ofReply: false)
        let nssetVersion = NSSet(set: acceptedClassesSet)
        // We need to pass through NSSet to add those WTF?!?!?
        let nssetVersionModified = nssetVersion.addingObjects(from: [NSArray.self, NSString.self, NSNumber.self])
        let finalSet = nssetVersionModified as Set
        interface.setClasses(finalSet, for: sel, argumentIndex: 0, ofReply: false)

        newConnection.exportedInterface = interface
        newConnection.exportedObject = self;
        newConnection.invalidationHandler = (() -> Void)? {
            if let indexValue = self.connections.index(of: newConnection) {
                self.connections.remove(at: indexValue)
            }
            
            if self.connections.count == 0 {
                self.shouldQuit = true
            }
        }
        self.connections.append(newConnection)
        newConnection.resume()
        return true
    }
    
    /*
     Return bundle version for this helper
     */
    func getVersion(reply: (String) -> Void) {
        reply(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)
    }
    
    /*
     Return installed SmartDNSConfiguration revision
     returns 0 if no smartDNSConf is installed
     */
    func getInstalledSmartDNSConfRevision(reply: (UInt) -> Void) {
        if let conf = getInstalledSmartDNSConf() {
            reply(conf.revision)
            return
        }
        reply(0)
        return
    }

    func flushDNSCache(reply: @escaping (NSNumber, String) -> Void) {
        // Send a hang up to mDNSResponder, launchd will restart the daemon
        // and the DNS cache will be cleared as spillover effect
        let command = "/usr/bin/killall"
        let arguments = ["-HUP", "mDNSResponder"]
        
        // Run the task
        runTask(command: command, arguments: arguments, reply:reply)
    }
    
    func installSmartDNSConf(_ smartDNSConf: SmartDNSConfiguration, reply: (Bool, String) -> Void) {
        // If there's a conf installed remove it before installing new one
        if let conf = getInstalledSmartDNSConf() {
            if !removeInstalledSmartDNSConf(conf) {
                reply(false, "Couldn't remove previous smartDNSConf")
                return
            }
        }
        
        // Create /etc/resolver dir if not present
        if !directoryExistsAtPath(resolverDir) {
            do {
                try FileManager.default.createDirectory(atPath: resolverDir, withIntermediateDirectories: true)
            } catch {
                reply(false, "Unable to create directory: \(error)")
                return
            }
        }
        
        // Create conf files for the smartDNSConf domains using the DNS
        let fileContent = smartDNSConf.DNS.map { "nameserver \($0)" }.joined(separator: "\n")
        let filesPath = smartDNSConf.domains.map { "\(resolverDir)/\($0)" }
        for file in filesPath {
            do {
                if FileManager.default.fileExists(atPath: file) {
                    let oldFileContent = try String(contentsOfFile: file, encoding: .utf8)
                    if oldFileContent != fileContent {
                        try fileContent.write(toFile: file, atomically: false, encoding: .utf8)
                    }
                } else {
                    try fileContent.write(toFile: file, atomically: false, encoding: .utf8)
                }
            } catch {
                reply(false, "Error updating domain conf for file \(file):\(error)")
                return
            }
        }
        
        // Write a json serialized version of SmartDNSConf we just installed
        // so we can later check which is currently installed
        let installedConfPath = "\(resolverDir)/\(configurationFile)"
        do {
            if FileManager.default.fileExists(atPath: installedConfPath) {
                try FileManager.default.removeItem(atPath: installedConfPath)
            }
            let payload: Data = try JSONEncoder().encode(smartDNSConf)
            if let jsonString = String(data: payload, encoding: .utf8) {
                try jsonString.write(toFile: installedConfPath, atomically: true, encoding: .utf8)
            }
        } catch {
            reply(false, "Error writing installed smartDNS configuration; \(error)")
            return
        }

        reply(true, "SmartDNSConfiguration installed successfuly")
    }
    
    private func getInstalledSmartDNSConf() -> SmartDNSConfiguration? {
        let installedConfPath = "\(resolverDir)/\(configurationFile)"
        if FileManager.default.fileExists(atPath: installedConfPath) {
            do {
                let payload = try Data(contentsOf: URL(fileURLWithPath: installedConfPath))
                let smartDNSConf = try JSONDecoder().decode(SmartDNSConfiguration.self, from: payload)
                return smartDNSConf
            } catch {
                NSLog("Couldn't load installed SmartDNSConf")
                return nil
            }
        }
        NSLog("No SmartDNSConfiguration installed")
        return nil
    }
    
    private func removeInstalledSmartDNSConf(_ conf: SmartDNSConfiguration) -> Bool {
        let filesPath = conf.domains.map { "\(resolverDir)/\($0)" }
        for file in filesPath {
            do {
                if FileManager.default.fileExists(atPath: file) {
                    try FileManager.default.removeItem(atPath: file)
                }
            } catch {
                NSLog("Couldn't remove domain file \(file): \(error)")
                return false
            }
        }
        do {
            try FileManager.default.removeItem(atPath: "\(resolverDir)/\(configurationFile)")
            return true
        } catch {
            NSLog("Error couldn't remove smartDNS configuration file: \(error)")
            return false
        }
    }
    
    private func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /*
     Not really used in this test app, but there might be reasons to support multiple simultaneous connections.
     */
    private func connection() -> NSXPCConnection
    {
        return self.connections.last!
    }
    
    
    /*
     General private function to run an external command
     */
    private func runTask(command: String, arguments: Array<String>, reply:@escaping ((NSNumber, String) -> Void)) -> Void
    {
        let task:Process = Process()
        let stdOut:Pipe = Pipe()
        let stdErr:Pipe = Pipe()

        task.launchPath = command
        task.arguments = arguments
        task.standardOutput = stdOut
        task.standardError = stdErr

        task.terminationHandler = { task in
            let data = stdOut.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: String.Encoding.utf8)
            reply(NSNumber(value: task.terminationStatus), output!)
        }

        task.launch()
    }
}
