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
        
        newConnection.exportedInterface = NSXPCInterface(with:PrivilegedHelperProtocol.self)
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
     Functions to run from the main app
     */
    func flushDNSCache(reply: @escaping (NSNumber, String) -> Void) {
        // Send a hang up to mDNSResponder, launchd will restart the daemon
        // and the DNS cache will be cleared as spillover effect
        let command = "/usr/bin/killall"
        let arguments = ["-HUP", "mDNSResponder"]
        
        // Run the task
        runTask(command: command, arguments: arguments, reply:reply)
    }
    
    func setCustomDNS(dns: [String], for domains: [String], reply: (Bool, [String: String]) -> Void) {
    var failedDomains = [String: String]()
        let path = "/etc/resolver"
        if !directoryExistsAtPath(path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch let error as NSError {
                NSLog("Unable to create directory \(error.debugDescription)")
                reply(false, failedDomains)
                return
            }
        }
        let fileContent = dns.map { "nameserver \($0)" }.joined(separator: "\n")
        let filesPath = domains.map { "\(path)/\($0)" }
        for (index, file) in filesPath.enumerated() {
            if FileManager.default.fileExists(atPath: file) {
                do {
                    let oldFileContent = try String(contentsOfFile: file, encoding: .utf8)
                    if oldFileContent != fileContent {
                        do {
                            try fileContent.write(toFile: file, atomically: false, encoding: .utf8)
                        } catch {
                            failedDomains[domains[index]] = "Couldn't write to file"
                        }
                    }
                }
                catch {
                    failedDomains[domains[index]] = "Couldn't read file"
                }
            } else {
                do {
                    try fileContent.write(toFile: file, atomically: false, encoding: .utf8)
                } catch {
                    failedDomains[domains[index]] = "Couldn't write to file"
                }
            }
        }
        reply(true, failedDomains)
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
