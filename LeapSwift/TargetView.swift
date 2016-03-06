//
//  TargetView.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 2/19/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Cocoa

protocol TargetViewDelegate {
    func targetViewDidSelect(target: TargetView, atLocation: NSPoint)
}

class TargetView: NSControl {
    
    var hovered: Bool = false
    var selected: Bool = false {
        didSet {
            self.needsDisplay = true
        }
    }
    var prompted: Bool = false {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var center: CGPoint {
        get {
            return CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        }
    }
    
    var delegate: TargetViewDelegate!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let options: NSTrackingAreaOptions = [.ActiveAlways, .MouseEnteredAndExited]
        let trackingArea = NSTrackingArea.init(
            rect: frameRect,
            options: options,
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func drawRect(rect: NSRect) {
        super.drawRect(rect)
                
        if let gc = NSGraphicsContext.currentContext() {
            gc.saveGraphicsState()
            
            NSColor.grayColor().setStroke()
            
            if self.prompted {
                NSColor.redColor().setFill()
            } else if self.selected {
                NSColor.whiteColor().setFill()
            } else {
                NSColor.whiteColor().setFill()
            }
            
            let circlePath = NSBezierPath()
            circlePath.appendBezierPathWithOvalInRect(rect.insetBy(2.0))
            circlePath.lineWidth = 2.0
            
            circlePath.stroke()
            circlePath.fill()
            
            gc.restoreGraphicsState()
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if self.delegate != nil {
            self.delegate.targetViewDidSelect(self, atLocation: theEvent.locationInWindow)
        }
    }
    
    override func updateTrackingAreas() {
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        let options: NSTrackingAreaOptions = [.ActiveAlways, .MouseEnteredAndExited]
        let trackingArea = NSTrackingArea.init(
            rect: self.frame,
            options: options,
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(trackingArea)
    }

}
