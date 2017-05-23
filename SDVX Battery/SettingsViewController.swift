//
//  SettingsViewController.swift
//  SDVX Battery
//
//  Created by CenoX on 2016. 5. 9..
//  Copyright © 2016년 CenoX. All rights reserved.
//

import Cocoa
import IOKit.ps

class SettingsViewController: NSViewController {

    @IBOutlet weak var normal: NSButton!
    @IBOutlet weak var permissive: NSButton!
    @IBOutlet weak var excessive: NSButton!
    @IBOutlet weak var infinite: NSButton!
    
    @IBOutlet weak var scale1: NSButton!
    @IBOutlet weak var scale2: NSButton!
    @IBOutlet weak var scale3: NSButton!
    
    var themeValue: Int = 0
    var scaleValue: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        loadPreviousSettings()
    }
    
}

extension SettingsViewController {
    
    // Load previous settings.
    func loadPreviousSettings() {
        guard let fm = SDVXFileManager.getApplicationDirectory() else { fatalError("FUCKING NIL") }
        let path = fm.appendingPathComponent("Settings.plist")
        
        let theme = NSDictionary(contentsOf: path)
        if theme == nil {
            fatalError("THEME FUCKING NIL")
        }
        print("\(theme)")
        
        let themeSeg = theme?.object(forKey: "Theme") as? String
        let scaleSeg = theme?.object(forKey: "Scale") as? String
        
        if let themeIndex = Int(themeSeg!) {
            switch themeIndex {
            case 0:
                self.normal.state = 1
                break;
            case 1:
                self.permissive.state = 1
                break;
            case 2:
                self.excessive.state = 1
                break;
            case 3:
                self.infinite.state = 1
                break;
            default:
                break;
            }
        }
        
        if let scaleIndex = Int(scaleSeg!) {
            switch scaleIndex {
            case 0:
                self.scale1.state = 1
                break;
            case 1:
                self.scale2.state = 1
                break;
            case 2:
                self.scale3.state = 1
                break;
            default:
                break;
            }
        }
        
    }
}

extension SettingsViewController {
    // Value
    // 0    - Normal
    // 1    - Permissive
    // 2    - Excessive
    // 3    - Infinite
    
    @IBAction func updateValue(_ sender: AnyObject) {
        if let button = sender as? NSButton {
            print("Update value: \(button.tag)")
            themeValue = button.tag
        }
    }
    
    @IBAction func updateScaleValue(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { fatalError("FUCKING SCALE BUTTON IS NIL!!!") }
        print("Update scale value: \(button.tag)")
        scaleValue = button.tag
    }
    
    @IBAction func saveData(_ sender: AnyObject) {
        let a = NSAlert()
        a.messageText = "Apply and restart?"
        a.informativeText = "Your settings will be affect next launch.\nDo you want restart app now?"
        a.addButton(withTitle: "Apply")
        a.addButton(withTitle: "Cancel")
        a.alertStyle = NSAlertStyle.warning
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
            if modalResponse == NSAlertFirstButtonReturn {
                guard let fm = SDVXFileManager.getApplicationDirectory() else { fatalError("FUCKING NIL") }
                let path = fm.appendingPathComponent("Settings.plist")
                
                let theme = NSMutableDictionary(contentsOf: path)
                theme?.setObject("\(self.themeValue)", forKey: "Theme" as NSCopying)
                theme?.setObject("\(self.scaleValue)", forKey: "Scale" as NSCopying)
                theme?.write(to: path, atomically: true)
                
                NSApplication.shared().relaunch(sender)
            }
        })
    }
    
    @IBAction func about(_ sender: AnyObject) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
    
    @IBAction func quit(_ sender: AnyObject) {
        NSApplication.shared().terminate(sender)
    }
    
}
