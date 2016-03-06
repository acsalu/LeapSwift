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
    
    @IBOutlet weak var handCount: NSTextField!
    
    @IBOutlet weak var stage: NSView!
    
    @IBOutlet weak var distanceSlider: NSSlider!
    @IBOutlet weak var widthSlider: NSSlider!
    
    var transformer: BaseTransformer = FingerTransformer.init(isRightHand: true, fingerIndex: 1)
    
    var targets: [TargetView]!
    
    var testIndex: Int = 0
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
    
    func resetStage() {
        testIndex = 0
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
        self.promptTarget()
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
    
    func promptTarget() {
        targets.map { target -> Void in
            target.prompted = false
        }
        targets[testOrder[testIndex]].prompted = true
    }
    
    // MARK: - TargetViewDelegate methods
    
    func targetViewDidSelect(target: TargetView, atLocation location: NSPoint) {
        
        guard testIndex < self.testOrder.count else {
            return
        }
        
        if target.tag == self.testOrder[testIndex] {
            print("tag: \(target.tag) center: \(target.center) mouse: \(location)")
            fittsTask.setSelectPointForCurrentTrial(location)
            target.selected = true
            ++testIndex
            
            if testIndex == self.testOrder.count {
                print("finish!")
                fittsTask.finish()
                
            } else {
                fittsTask.startNextTrial(fromTarget: targets[testOrder[testIndex - 1]], toTarget: targets[testOrder[testIndex]])
                promptTarget()
            }
        } else {
            fittsTask.addClickCountToCurrentTrial()
        }
    }
    
    // MARK: - LeapListener methods
    
    func updateStatus(status: String) {
        print(status)
//        self.deviceStatus.stringValue = "Status: \(status)"
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
    
    var lastFrame: LeapFrame?
    
    func onFrame(notification: NSNotification!) {
        let controller = notification.object as! LeapController
        let frame = controller.frame(0)
        
        
        self.handCount.stringValue = "hands: \(frame.hands.count)"
        
        let event = CGEventCreate(nil);
        let currentMouseLocation = CGEventGetLocation(event);
        
//        print("Current: \(currentMouseLocation)")
        
        if let mouseDiff = self.transformer.transformFrame(frame) {
            let mouseWarpLocation = CGPointMake(currentMouseLocation.x + mouseDiff.x, currentMouseLocation.y + mouseDiff.y)
//            print("New: \(mouseWarpLocation)")
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
    
    override func mouseDown(theEvent: NSEvent) {
        self.fittsTask.addClickCountToCurrentTrial()
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

