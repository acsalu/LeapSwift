//
//  FittsTask.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 2/22/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Foundation
import CGRectExtensions

class FittsTask {
    
    // MARK: - Stored Properties
    var trials = [Trial]()
    
    // MARK: - Computed Properties
    var averageMovementTime: NSTimeInterval {
        get {
            return self.trials.reduce(0.0) {
                (duration: NSTimeInterval, trial: Trial) -> NSTimeInterval in
                    return duration + trial.elapsedTime
            } / Double(self.trials.count)
        }
    }
    
    var accuracy: Float {
        get {
            return Float(trials.count) / Float(numberOfClicks)
        }
    }
    
    var numberOfClicks: Int {
        get {
            return self.trials.reduce(0, combine: { (clicks, trial) -> Int in
                return clicks + trial.numberOfClicks
            })
        }
    }
    
    // TODO:
    var throughput: Float {
        get {
            return 0.0
        }
    }
    
    var effectiveAmplitude: CGFloat {
        get {
            var eas = [CGFloat]()
            for (index, trial) in trials.enumerate() {
                var ea = trial.dx + trial.from.distanceToPoint(trial.to)
                if index > 0 {
                    ea += trials[index - 1].dx
                }
                eas.append(ea)
            }
            return eas.reduce(0.0, combine: +) / CGFloat(eas.count)
        }
    }
    
    var standardDeviationOfDx: CGFloat {
        get {
            guard !trials.isEmpty else {
                return 0.0
            }
            
            
            let dxs = trials.map { $0.dx }
            let mean = dxs.reduce(0.0, combine: +) / CGFloat(dxs.count)
            let sumOfSquaredMeanDiff = dxs.map{ pow($0 - mean, 2.0) }.reduce(0.0, combine: +)
            return sqrt(sumOfSquaredMeanDiff)
        }
    }
    
    
    // MARK: - Trial Control Methods
    func startNextTrial(fromTarget from: TargetView, toTarget to: TargetView) {
        
        if !self.trials.isEmpty {
            self.trials.last!.stop()
        }
        
        let trial = Trial.init(fromTarget: from, toTarget: to)
        self.trials.append(trial)
        trial.start()
    }
    
    func finish() {
        
        guard !trials.isEmpty else {
            return
        }
        
        self.trials.last!.stop()
        
        print("Finish Fitts Task")
        print("\(self.trials.count) trials")
        print("\(self.numberOfClicks) clicks")
        print("Average MT: \(averageMovementTime)")
        print("Accuracy: \(accuracy)")
        print("Effective Amplitude: \(effectiveAmplitude)")
        print("Standard Deviation of dx: \(standardDeviationOfDx)")
    }
    
    func clear() {
        self.trials.removeAll()
    }
    
    func addClickCountToCurrentTrial() {
        if self.trials.isEmpty {
            return
        }
        
        self.trials.last!.addClickCount()
    }
    
    func setSelectPointForCurrentTrial(select: NSPoint) {
        if self.trials.isEmpty {
            return
        }
        
        self.trials.last!.select = select
    }
}

class Trial {
    
    let from: CGPoint
    let to: CGPoint
    var select: CGPoint!
    
    var startTime: NSTimeInterval!
    var stopTime: NSTimeInterval!
    var elapsedTime: NSTimeInterval!
    var numberOfClicks: Int = 1
    
    
    
    // TODO:
    var dx: CGFloat {
        
        get {
            let a = from.distanceToPoint(to)
            let b = select.distanceToPoint(to)
            let c = select.distanceToPoint(from)
            
            return (c * c - b * b - a * a) / (2.0 * a)
        }
    }
    
    init(fromTarget: TargetView, toTarget: TargetView) {
        self.from = fromTarget.center
        self.to = toTarget.center
    }
    
    func start() {
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
    }
    
    func stop() {
        self.stopTime = NSDate.timeIntervalSinceReferenceDate()
        self.elapsedTime = self.stopTime - self.startTime
    }
    
    func addClickCount() {
        ++self.numberOfClicks
    }
}