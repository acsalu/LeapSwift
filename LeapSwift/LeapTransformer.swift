//
//  LeapTransformer.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 2/20/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Cocoa

class BaseTransformer {
    
    func transformFrame(frame: LeapFrame) -> CGPoint? {
        preconditionFailure("This method must be overridden")
    }
    
    func transformCoordinate(vector: LeapVector) -> NSPoint {
        return NSMakePoint(self.relativeX(vector.x), self.relativeY(vector.y))
    }
    
    func relativeValue(value: Float, originalBound: (Float, Float), newBound: (Float, Float)) -> Float {
        let (lower, upper) = originalBound
        let ratio = (value - lower) / (upper - lower)
        let (newLower, newUpper) = newBound
        
        return newLower + ratio * (newUpper - newLower)
    }
    
    func relativeX(x: Float) -> CGFloat {
        let width = NSScreen .mainScreen()?.frame.size.width
        return CGFloat(self.relativeValue(x, originalBound: (-60.0, 60.0), newBound: (0.0, Float(width!))))
    }
    
    func relativeY(y: Float) -> CGFloat {
        let height = NSScreen .mainScreen()?.frame.size.height
        return CGFloat(self.relativeValue(y, originalBound: (180.0, 60.0), newBound: (0.0, Float(height!))))
    }
    
    func handleGestures(gestures: [LeapGesture]) {
        for gesture in gestures {
            for hand in gesture.hands as! [LeapHand] {
                if hand.isLeft {
                    switch gesture.type {
                    case LEAP_GESTURE_TYPE_CIRCLE:
                        print("circle")
                    case LEAP_GESTURE_TYPE_KEY_TAP:
                        print("key tap")
                    case LEAP_GESTURE_TYPE_SCREEN_TAP:
                        print("screen tap")
                    case LEAP_GESTURE_TYPE_SWIPE:
                        print("swipe")
                    default:
                        break
                    }
                }
            }
        }
    }
}

class PalmTransformer: BaseTransformer {
    let isRightHand: Bool
    
    init(isRightHand: Bool) {
        self.isRightHand = isRightHand
    }
    
    override func transformFrame(frame: LeapFrame) -> CGPoint? {
        
        self.handleGestures(frame.gestures(nil) as! [LeapGesture])
        for hand in frame.hands as! [LeapHand] {
            if hand.isRight == self.isRightHand {
                let mouseWarpLocation = self.transformCoordinate(hand.stabilizedPalmPosition)
                return mouseWarpLocation
            }
        }
        return nil
    }
}

class FingerTransformer: BaseTransformer {
    let isRightHand: Bool
    let fingerIndex: UInt32
    
    init(isRightHand: Bool, fingerIndex: UInt32) {
        self.isRightHand = isRightHand
        self.fingerIndex = fingerIndex
    }
    
    override func transformFrame(frame: LeapFrame) -> CGPoint? {
        
        self.handleGestures(frame.gestures(nil) as! [LeapGesture])
        for hand in frame.hands as! [LeapHand] {
            if hand.isRight == self.isRightHand {
                for finger in hand.fingers as! [LeapFinger] {
                    if finger.type == LeapFingerType.init(fingerIndex) {
                        
                        let velocity = LeapVector(vector: finger.tipVelocity)
                        velocity.z = 0.0
                        
                        var newMagnitude: Float!
                        
                        if velocity.magnitude <= 20.0 {
                            
                            newMagnitude = velocity.magnitude * 0.01
                            
                        } else if velocity.magnitude < 200.0 {
                            
                            newMagnitude = 2.0 + (velocity.magnitude - 2.0) * 0.05
                            
                        } else {
                            newMagnitude = 11.9 + (velocity.magnitude - 11.9) * 0.1
                        }
                        
                        let scale = newMagnitude / velocity.magnitude
                        
                        let diff = CGPointMake(CGFloat(finger.tipVelocity.x * scale), -CGFloat(finger.tipVelocity.y * scale))
                        return diff
                    }
                }
            }
        }
        
        return nil
    }
}

class FingerXZTransformer: BaseTransformer {
    let isRightHand: Bool
    let fingerIndex: UInt32
    
    init(isRightHand: Bool, fingerIndex: UInt32) {
        self.isRightHand = isRightHand
        self.fingerIndex = fingerIndex
    }
    
    override func transformFrame(frame: LeapFrame) -> CGPoint? {
        
        self.handleGestures(frame.gestures(nil) as! [LeapGesture])
        for hand in frame.hands as! [LeapHand] {
            if hand.isRight == self.isRightHand {
                for finger in hand.fingers as! [LeapFinger] {
                    if finger.type == LeapFingerType.init(fingerIndex) {
                        let mouseWarpLocation = self.transformCoordinate(finger.stabilizedTipPosition)
                        return mouseWarpLocation
                    }
                }
            }
        }
        
        return nil
    }
    
    override func transformCoordinate(vector: LeapVector) -> NSPoint {
        return NSMakePoint(self.relativeX(vector.x), self.relativeY(vector.z))
    }
    
    override func relativeY(y: Float) -> CGFloat {
        print(y)
        let height = NSScreen .mainScreen()?.frame.size.height
        return CGFloat(self.relativeValue(y, originalBound: (-150.0, -10.0), newBound: (0.0, Float(height!))))
    }
}

