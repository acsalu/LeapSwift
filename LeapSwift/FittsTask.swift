//
//  FittsTask.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 2/22/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Foundation
import CGRectExtensions

enum TaskState {
    case None, Before, During, End
}

class FittsTask {
    
    // MARK: - Stored Properties
    var trials = [Trial]()
    var numberOfTrialsCompleted: Int!
    var state: TaskState = .None {
        didSet {
            switch self.state {
            case .Before:
                let trial = trials[0]
                trial.fromTarget.prompted = true
            case .During:
                let trial = trials[numberOfTrialsCompleted]
                trial.fromTarget.prompted = false
                trial.toTarget.prompted = true
                if let lastTrial = lastTrial {
                    lastTrial.stop()
                }
                trial.start()
            case .End:
                if let lastTrial = lastTrial {
                    lastTrial.stop()
                }
                finish()
            case .None:
                break
            }
        }
    }
    
    // MARK: - Computed Properties
    var currentTarget: TargetView? {
        get {
            if state == .During {
                return trials[numberOfTrialsCompleted!].toTarget
            }
            
            return nil
        }
    }
    
    var lastTrial: Trial? {
        get {
            if state == .End {
                return trials.last!
            }
            
            guard state == .During else {
                return nil
            }
            
            guard numberOfTrialsCompleted > 0 else {
                return nil
            }
            
            return trials[numberOfTrialsCompleted - 1]
        }
    }
    
    var meanMovementTime: NSTimeInterval {
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
    
    var throughput: Double {
        get {
            return Double(log(effectiveAmplitude / (4.133 * standardDeviationOfDx) + 1)) / meanMovementTime
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
    func stepOverWithLocation(location: NSPoint) {
        switch self.state {
        case .Before:
            numberOfTrialsCompleted = 0
            self.state = .During
        case .During:
            numberOfTrialsCompleted = numberOfTrialsCompleted + 1
            
            if let lastTrial = lastTrial {
                lastTrial.select = location
            }
            
            if numberOfTrialsCompleted == self.trials.count {
                self.state = .End
            } else {
                self.state = .During
            }
        case .End: break
        case .None: break
        }
    }
    
    
    
    func addTrial(fromTarget from: TargetView, toTarget to: TargetView) {
        let trial = Trial.init(fromTarget: from, toTarget: to)
        self.trials.append(trial)
    }
    
    func finish() {
        
        guard !trials.isEmpty else {
            return
        }
        
        self.trials.last!.stop()
        
        print("Finish Fitts Task")
        print("\(self.trials.count) trials")
        print("\(self.numberOfClicks) clicks")
        print("Average MT: \(meanMovementTime)")
        print("Accuracy: \(accuracy)")
        print("Effective Amplitude: \(effectiveAmplitude)")
        print("Standard Deviation of dx: \(standardDeviationOfDx)")
        print("Throughput: \(throughput)")
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
    
    let fromTarget: TargetView
    let toTarget: TargetView
    
    let from: CGPoint
    let to: CGPoint
    var select: CGPoint!
    
    var startTime: NSTimeInterval!
    var stopTime: NSTimeInterval!
    var elapsedTime: NSTimeInterval!
    var numberOfClicks: Int = 1
    
    var dx: CGFloat {
        get {
            let a = from.distanceToPoint(to)
            let b = select.distanceToPoint(to)
            let c = select.distanceToPoint(from)
            
            return (c * c - b * b - a * a) / (2.0 * a)
        }
    }
    
    init(fromTarget: TargetView, toTarget: TargetView) {
        self.fromTarget = fromTarget
        self.toTarget = toTarget
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