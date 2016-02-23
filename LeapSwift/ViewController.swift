//
//  ViewController.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 2/9/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Cocoa
import QuartzCore
import CoreGraphics
import CGRectExtensions

class ViewController: NSViewController, LeapListener, TargetViewDelegate, NSWindowDelegate {

    var controller: LeapController!
    
    @IBOutlet weak var deviceStatus: NSTextField!
    @IBOutlet weak var handCount: NSTextField!
    
    @IBOutlet weak var stage: NSView!
    
    @IBOutlet weak var distanceSlider: NSSlider!
    @IBOutlet weak var widthSlider: NSSlider!
    
    var transformer: BaseTransformer?
    
    let palmTransformer = PalmTransformer.init(isRightHand: true)
    let fingerTransformer = FingerTransformer.init(isRightHand: true, fingerIndex: 1)
    let fingerXZTransformer = FingerXZTransformer.init(isRightHand: true, fingerIndex: 1)
    
    var targets: [TargetView]!
    
    var testProgress: Int?
    var testOrder: [Int]!
    
    let fittsTask = FittsTask()
    
    var radius: CGFloat {
        get {
            return self.stage.bounds.size.width * CGFloat(self.distanceSlider.floatValue) / 2.0
        }
    }
    
    var targetSize: CGFloat {
        get {
            return CGFloat(self.widthSlider.floatValue)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.controller = LeapController.init(listener: self)
        self.transformer = palmTransformer
        
        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyDownMask) { (aEvent) -> NSEvent? in
            self.keyDown(aEvent)
            return aEvent
        }
        
        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyUpMask) { (aEvent) -> NSEvent? in
            self.keyUp(aEvent)
            return aEvent
        }
        
        self.stage.wantsLayer = true
        self.stage.layer?.borderColor = NSColor.blackColor().CGColor
        self.stage.layer?.borderWidth = 3.0
        
        self.updateStage()
        
        let window = NSApplication.sharedApplication().windows[0]
        window.delegate = self;
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // IBActions
    @IBAction func updateButtonPressed(sender: NSButton) {
        self.updateStage()
    }
    
    @IBAction func leapModeDidChange(sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            self.transformer = palmTransformer
        case 1:
            self.transformer = fingerTransformer
        case 2:
            self.transformer = fingerXZTransformer
        default:
            break
        }
    }
    
    
    func resetStage() {
        testProgress = nil
        testOrder = [0]
        var odd = 13
        var even = 1
        for i in 1...24 {
            if i % 2 == 1 {
                testOrder.append(odd++)
            } else {
                testOrder.append(even++)
            }
        }
        testOrder.append(0)
        
        self.stage.layer?.sublayers?.removeAll()
        for subview in self.view.subviews {
            if let target = subview as? TargetView {
                target.removeFromSuperview()
            }
        }
        self.targets = [TargetView]()
        self.fittsTask.clear()
    }
    
    func updateStage() {
        self.resetStage()
        self.registerTargetsWithDistance(self.radius * 2.0, andWidth: self.targetSize)
        self.promptNextTarget()
    }
    
    func registerTargetsWithDistance(distance: CGFloat, andWidth width: CGFloat) {
        
        let radius = distance / 2.0
        let baseCircleOutlineLayer = CALayer()
        baseCircleOutlineLayer.bounds = CGRectMake(0, 0, radius * 2, radius * 2)
        baseCircleOutlineLayer.borderColor = NSColor.grayColor().CGColor
        baseCircleOutlineLayer.borderWidth = 1.0
        baseCircleOutlineLayer.cornerRadius = radius
        baseCircleOutlineLayer.position = CGPointMake((self.stage.layer?.bounds.width)! / 2, (self.stage.layer?.bounds.height)! / 2)
//        self.stage.layer?.addSublayer(baseCircleOutlineLayer)
        
        let targetSize: CGFloat = width
        let center = CGPointMake((self.stage.layer?.bounds.width)! / 2, (self.stage.layer?.bounds.height)! / 2)
        
        for i in 0..<25 {
            let dx = radius * CGFloat(sin(2.0 * M_PI * Double(i) / 25.0))
            let dy = radius * CGFloat(cos(2.0 * M_PI * Double(i) / 25.0))
            
            let x = center.x + dx - targetSize + stage.frame.origin.x
            let y = center.y + dy - targetSize + stage.frame.origin.y
            
            print("\(i) \(x) \(y)")
            
            let target = TargetView.init(frame: CGRectMake(x, y, targetSize * 2, targetSize * 2))
            target.tag = i
            target.delegate = self
            
            targets.append(target)
            
            self.view.addSubview(target)
        }
    }
    
    func promptNextTarget() {
        if self.testProgress != nil {
            targets[testOrder[self.testProgress!]].prompted = false
            ++testProgress!
        } else {
            testProgress = 0
        }

        if let index = testProgress {
            if index < testOrder.count {
                targets[testOrder[index]].prompted = true
            }
        }
    }
    
    // MARK: - TargetViewDelegate methods
    
    func targetViewDidSelect(targetView: TargetView) {
        
        if targetView.tag == self.testOrder[testProgress!] {
            targetView.selected = true
            self.promptNextTarget()
            
            if testProgress! == self.testOrder.count {
                print("D: \(self.radius * 2.0), W: \(self.targetSize * 2.0)")
                fittsTask.finish()
            } else {
                fittsTask.startNewSubTask()
            }
        }
    }
    
    // MARK: - LeapListener methods
    
    func updateStatus(status: String) {
        print(status)
        self.deviceStatus.stringValue = "Status: \(status)"
    }

    func onInit(notification: NSNotification!) {
        self.updateStatus("Initialized")
    }
    
    func onConnect(notification: NSNotification!) {
        self.updateStatus("Connected")
        let controller = notification.object as! LeapController
        controller.enableGesture(LEAP_GESTURE_TYPE_CIRCLE, enable: true)
        controller.enableGesture(LEAP_GESTURE_TYPE_KEY_TAP, enable: true)
        controller.enableGesture(LEAP_GESTURE_TYPE_SCREEN_TAP, enable: true)
        controller.enableGesture(LEAP_GESTURE_TYPE_SWIPE, enable: true)
    }
    
    func onDisconnect(notification: NSNotification!) {
        self.updateStatus("Disconnected")
    }
    
    func onServiceConnect(notification: NSNotification!) {
        self.updateStatus("Service Connected")
    }
    
    func onServiceDisconnect(notification: NSNotification!) {
        self.updateStatus("Service Disconnected")
    }
    
    func onDeviceChange(notification: NSNotification!) {
        self.updateStatus("Device Changed")
    }
    
    func onExit(notification: NSNotification!) {
        self.updateStatus("Exited")
    }
    
    func onFrame(notification: NSNotification!) {
        let controller = notification.object as! LeapController
        let frame = controller.frame(0)
        
        
        self.handCount.stringValue = "hands: \(frame.hands.count)"
        
        if let mouseWarpLocation = self.transformer?.transformFrame(frame) {
            let eventSource = CGEventSourceCreate(.CombinedSessionState)
            CGEventSourceSetLocalEventsSuppressionInterval(eventSource, 0.0)
            CGAssociateMouseAndMouseCursorPosition(0)
            CGWarpMouseCursorPosition(mouseWarpLocation)
            CGAssociateMouseAndMouseCursorPosition(1)
        }
    }
    
    // MARK: - Key Events
    
    override func keyDown(event: NSEvent) {
//        print("keyDown: \(event.keyCode)")
        if event.keyCode == 49 {
            let event = CGEventCreate(nil);
            let cursor = CGEventGetLocation(event);
            
            let clickDown = CGEventCreateMouseEvent(nil, .LeftMouseDown, cursor, .Left)
            
            CGEventPost(CGEventTapLocation.CGHIDEventTap, clickDown)
        }
        super.keyDown(event)
    }
    
    override func keyUp(event: NSEvent) {
//        print("keyUP: \(event.keyCode)")
        if event.keyCode == 49 {
            let event = CGEventCreate(nil);
            let cursor = CGEventGetLocation(event);
            
            let clickUp = CGEventCreateMouseEvent(nil, .LeftMouseUp, cursor, .Left)
            
            CGEventPost(CGEventTapLocation.CGHIDEventTap, clickUp)
        }
        super.keyUp(event)
    }
    
    // MARK: - NSWindowDelegate methods
    func windowWillEnterFullScreen(notification: NSNotification) {
        self.resetStage()
    }
    
    func windowDidEnterFullScreen(notification: NSNotification) {
        self.updateStage()
    }
}

