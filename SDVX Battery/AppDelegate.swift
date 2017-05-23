//
//  AppDelegate.swift
//  SDVX Battery
//
//  Created by CenoX on 2016. 5. 9..
//  Copyright © 2016년 CenoX. All rights reserved.
//

import Cocoa

extension String {
    /// Rename componentsSeparatedByString -> Separate
    func separate(_ separator: String) -> [String] {
        return self.components(separatedBy: separator)
    }
}

extension NSImage {
    func resizeImage(_ width: CGFloat, _ height: CGFloat) -> NSImage {
        let img = NSImage(size: CGSize(width: width, height: height))
        
        img.lockFocus()
        let ctx = NSGraphicsContext.current()
        ctx?.imageInterpolation = .high
        self.draw(in: NSMakeRect(0, 0, width, height), from: NSMakeRect(0, 0, size.width, size.height), operation: .copy, fraction: 1)
        img.unlockFocus()
        
        return img
    }
}

extension NSApplication {
    func relaunch(_ sender: AnyObject?) {
        let task = Process()
        // helper tool path
        task.launchPath = Bundle.main.path(forResource: "relaunch", ofType: nil)!
        // self PID as a argument
        task.arguments = [String(ProcessInfo.processInfo.processIdentifier)]
        task.launch()
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var firstNum: NSImageView!
    @IBOutlet weak var secondNum: NSImageView!
    @IBOutlet weak var thirdNum: NSImageView!
    @IBOutlet weak var indicator: NSImageView!
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet weak var batteryImageView: NSImageView!
    
    var cachedBatteryLevel: Int = 0
    var lock: Int = 0
    
    let statusItem = NSStatusBar.system().statusItem(withLength: -2)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    var currentScale: Int = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        // Set menu
        print("Initializing App")
        if let button = statusItem.button {
            button.image = NSImage(named: "icon")
            button.action = #selector(AppDelegate.togglePopover)
        }
        print("Copy plists")
        for plistIndex in 0..<SDVXFileManager().plistList.count {
            SDVXFileManager.checkFileandSave(SDVXFileManager().plistList[plistIndex])
        }
        
        self.batteryImageView?.image = nil
        
        popover.contentViewController = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
        
        let kCGDesktopWindowLevel: CGWindowLevel =
            CGWindowLevelForKey(CGWindowLevelKey.desktopWindow)
        
        // Set Window
        self.window.backgroundColor = .clear
        self.window.isOpaque = false
        self.window.level = Int(kCGDesktopWindowLevel)
        self.window.orderBack(self)
        DispatchQueue.main.async(execute: {
            var timer = Timer()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(AppDelegate.getCurrentBatteryTheme), userInfo: nil, repeats: true)
            print(timer)
        })
        
        guard let fm = SDVXFileManager.getApplicationDirectory() else { fatalError("FUCKING NIL") }
        let path = fm.appendingPathComponent("Settings.plist")
        guard let theme = NSDictionary(contentsOf: path) else { fatalError("FUCKING THEME DIC IS NIL") }
        let scaleIndex = Int(theme.object(forKey: "Scale") as! String)
        switch scaleIndex! {
        case 0:
            self.currentScale = 1
            break;
        case 1:
            self.currentScale = 2
            break;
        case 2:
            self.currentScale = 4
            break;
        default:
            break;
        }
        self.controlWindowSize(self.currentScale)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(nil)
    }
}

extension AppDelegate {
    
    func controlWindowSize(_ scale: Int) {
        var rect: CGRect!
        DispatchQueue.main.async(execute: {
            
            if scale != 1 {
                rect = CGRect(x: 0, y: 157, width: self.window.frame.width / CGFloat(scale), height: self.window.frame.height / CGFloat(scale))
            } else {
                rect = CGRect(x: 0, y: 0, width: self.window.frame.width / CGFloat(scale), height: self.window.frame.height / CGFloat(scale))
            }
            
            self.window.setFrame(rect, display: true, animate: true)
            self.backgroundImageView.frame = CGRect(x: 0, y: 0, width: self.window.frame.width, height: self.window.frame.height)
            self.batteryImageView.frame = CGRect(x: 0, y: 0, width: self.window.frame.width, height: self.window.frame.height)
            self.firstNum.frame = CGRect(x: 0, y: 0, width: self.window.frame.width, height: self.window.frame.height)
            self.secondNum.frame = CGRect(x: 0, y: 0, width: self.window.frame.width, height: self.window.frame.height)
            self.thirdNum.frame = CGRect(x: 0, y: 0, width: self.window.frame.width, height: self.window.frame.height)
            self.indicator.frame = CGRect(x: 0, y: 0, width: self.window.frame.width, height: self.window.frame.height)
        })
    }

    func getCurrentBatteryTheme() {
        guard let fm = SDVXFileManager.getApplicationDirectory() else { fatalError("FUCKING NIL") }
        let path = fm.appendingPathComponent("Settings.plist")
        
        guard let theme = NSDictionary(contentsOf: path) else { fatalError("FUCKING THEME DIC IS NIL") }
        
        guard let themeIndex = Int(theme.object(forKey: "Theme") as! String) else { fatalError("FUCKING VALUES ARE NIL!!") }
        
        self.updateBatteryLevelWithScale(themeIndex)
    }
    
    func updateBatteryLevelWithScale(_ theme: Int) {
        
        guard let batteryLevel = self.getBatteryLevel() else { fatalError("Battery level is nil.") }
        let scale = CGFloat(self.currentScale); let percentage = 100
        let appWidth = self.window.contentView!.frame.width; let appHeight = self.window.contentView!.frame.height
        
        // 배터리 레벨을 변수로 따로 저장하여, 값이 변경됬을 때만 이벤트를 실행
        if batteryLevel != cachedBatteryLevel {
            cachedBatteryLevel = batteryLevel
            
            if batteryLevel == 100 {
                self.firstNum.isHidden = false
                self.secondNum.image = NSImage(named: "Mid_n0")
                self.thirdNum.image = NSImage(named: "End_n0")
            } else {
                self.firstNum.isHidden = true
                self.secondNum.image = NSImage(named: "Mid_n\(batteryLevel / 10)")
                self.thirdNum.image = NSImage(named: "End_n\(batteryLevel % 10)")
            }
            
            switch theme {
            case 0: // Normal
                let windowHeight = 740
                let heightPoint = (batteryLevel * windowHeight / percentage) / self.currentScale
                let heightPrefix = CGFloat(68) / scale
                
                self.animateIndicator(CGFloat(heightPoint))
                
                DispatchQueue.main.async(execute: {
                    self.backgroundImageView.image = NSImage(named: "ui_gauge_base")
                })
                
                let imageIndex = (batteryLevel > 70) ? 1 : 2
                
                let image = cropImageWithScale("\(imageIndex)", width: appWidth, height: appHeight, point: CGFloat(heightPoint), prefix: heightPrefix)
                
                DispatchQueue.main.async(execute: {
                    self.batteryImageView.frame = CGRect(x: 0, y: 0, width: appWidth, height: CGFloat(heightPoint) + heightPrefix)
                    self.batteryImageView.image = image
                })
                break;
            case 1: // Permissive
                let windowHeight = 703; let lineHeightPrefix = 20;
                let heightPoint = (lineHeightPrefix + (batteryLevel * windowHeight / percentage)) / self.currentScale
                let heightPrefix = CGFloat(68) / scale
                
                self.animateIndicator(CGFloat(heightPoint))
                
                DispatchQueue.main.async(execute: {
                    self.backgroundImageView.image = NSImage(named: "ui_gauge_permissive_base")
                })
                
                let image = cropImageWithScale("permissive", width: appWidth, height: appHeight, point: CGFloat(heightPoint), prefix: heightPrefix)
                
                DispatchQueue.main.async(execute: {
                    self.batteryImageView.frame = CGRect(x: 0, y: 0, width: appWidth, height: CGFloat(heightPoint) + heightPrefix)
                    self.batteryImageView.image = image
                })
                break;
            case 2: // Excessive
                let windowHeight = 710; let lineHeightPrefix = 20
                let heightPoint = (lineHeightPrefix + (batteryLevel * windowHeight / percentage)) / self.currentScale
                let heightPrefix = CGFloat(68) / scale
                
                self.animateIndicator(CGFloat(heightPoint))
                
                DispatchQueue.main.async(execute: {
                    self.backgroundImageView.image = NSImage(named: "ui_gauge_excessive_base")
                })
                
                let image = cropImageWithScale("excessive", width: appWidth, height: appHeight, point: CGFloat(heightPoint), prefix: heightPrefix)
                
                DispatchQueue.main.async(execute: {
                    self.batteryImageView.frame = CGRect(x: 0, y: 0, width: appWidth, height: CGFloat(heightPoint) + heightPrefix)
                    self.batteryImageView.image = image
                })
                break;
            case 3: // Infinite
                let windowHeight = 710; let lineHeightPrefix = 18
                let heightPoint = (lineHeightPrefix + (batteryLevel * windowHeight / percentage)) / self.currentScale
                let heightPrefix = CGFloat(68) / scale
                
                self.animateIndicator(CGFloat(heightPoint))
                
                DispatchQueue.main.async(execute: {
                    self.backgroundImageView.image = NSImage(named: "ui_gauge_infinite_base")
                })
                
                let image = cropImageWithScale("infinite", width: appWidth, height: appHeight, point: CGFloat(heightPoint), prefix: heightPrefix)
                
                DispatchQueue.main.async(execute: {
                    self.batteryImageView.frame = CGRect(x: 0, y: 0, width: appWidth, height: CGFloat(heightPoint) + heightPrefix)
                    self.batteryImageView.image = image
                })
                break;
            default:
                break;
            }
        }
    }
    
    func cropImageWithScale(_ theme: String, width: CGFloat, height: CGFloat, point: CGFloat, prefix: CGFloat) -> NSImage {
        let gaugeImage = NSImage(named: "ui_gauge_\(theme)_\(self.currentScale)")?.tiffRepresentation
        let source = CGImageSourceCreateWithData(gaugeImage! as CFData, nil)
        let image = CGImageSourceCreateImageAtIndex(source!, 0, nil)
        
        let imageRect = CGRect(x: 0, y: height - (point + prefix), width: width, height: point + prefix)
        let croppedImage = image?.cropping(to: imageRect)
        
        let result = NSImage(cgImage: croppedImage!, size: NSSize(width: width, height: point + prefix))
        
        return result
    }

    func animateIndicator(_ heightPosition: CGFloat) {
        var indicatorHeight = self.firstNum.frame
        indicatorHeight.origin.y = heightPosition
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            self.secondNum.layer!.position = self.secondNum.layer!.presentation()!.position
        }
        
        let animation = CABasicAnimation(keyPath: "position")
        let currentPosition: CGPoint = secondNum.layer!.presentation()!.position
        animation.duration = 0.3
        animation.fromValue = NSValue(point: currentPosition)
        animation.toValue = NSValue(point: CGPoint(x: currentPosition.x, y: heightPosition))
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        self.firstNum.layer?.add(animation, forKey: "transform")
        self.secondNum.layer?.add(animation, forKey: "transform")
        self.thirdNum.layer?.add(animation, forKey: "transform")
        self.indicator.layer?.add(animation, forKey: "transform")
        
        CATransaction.commit()
    }
    
    func getBatteryLevel() -> Int? {
        let sources = IOPSCopyPowerSourcesList(IOPSCopyPowerSourcesInfo().takeRetainedValue()).takeRetainedValue() as NSArray
        
        var batteryLevel: Int = 0
        
        for ps in sources {
            // Fetch the information for a given power source out of our snapshot
            guard let info: NSDictionary = IOPSGetPowerSourceDescription(IOPSCopyPowerSourcesInfo().takeRetainedValue(), ps as CFTypeRef!)?.takeUnretainedValue()
                else { return nil }
            
            // Pull out the name and current capacity
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                batteryLevel = capacity
            }
        }
        return batteryLevel
    }
}

open class SDVXFileManager {
    
    internal let plistList = ["Settings.plist"]
    
    class func getApplicationDirectory() -> URL? {
        let BundleString = "SDVXBatteryWidget"
        let fm = FileManager.default
        var dirPath: URL? = nil
        
        let appSupportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if appSupportDir.count > 0 {
            dirPath = appSupportDir[0].appendingPathComponent(BundleString)
            do {
                try fm.createDirectory(at: dirPath!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        return dirPath
    }
    
    class func checkFileandSave(_ plistName: String) {
        let fileManager: FileManager = .default
        guard let fm = getApplicationDirectory() else { fatalError("FUCKING NIL") }
        let path = fm.appendingPathComponent(plistName)
        if !fileManager.fileExists(atPath: path.path) {
            print("Copy Started.")
            let separateType = plistName.components(separatedBy: ".")
            let name = separateType[0]
            let type = separateType[1]
            print(name + "." + type)
            let bundle = Bundle.main.url(forResource: name, withExtension: type)
            if (bundle == nil) {
                print("requested plist is not found.")
            } else {
                print("requested plist found.")
                do {
                    print("\nStart copy process.")
                    try fileManager.copyItem(at: bundle!, to: path)
                    print("Done!")
                } catch let errors as NSError {
                    print("\n \(errors)")
                }
            }
        } else {
            print("File already exists.\n")
        }
    }
}

/* EVENTMONITOR */
open class EventMonitor {
    fileprivate var monitor: AnyObject?
    fileprivate let mask: NSEventMask
    fileprivate let handler: (NSEvent?) -> ()
    
    
    public init(mask: NSEventMask, handler: @escaping (NSEvent?) -> ()) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    
    open func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as AnyObject?
    }
    
    open func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
