//
//  FittsTask.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 2/22/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Foundation

class FittsTask {
    var subtasks = [FittsSubTask]()
    
    var duration: NSTimeInterval {
        get {
            return self.subtasks.reduce(0.0) {
                (duration: NSTimeInterval, subtask: FittsSubTask) -> NSTimeInterval in
                    return duration + subtask.elapsedTime
            }
        }
    }
    
    var misses: Int {
        get {
            return self.subtasks.reduce(0) {
                (misses: Int, subtask: FittsSubTask) -> Int in
                return misses + subtask.misses
            }
        }
    }
    
    func startNewSubTask() {
        
        if !self.subtasks.isEmpty {
            self.subtasks.last!.stop()
        }
        
        let subtask = FittsSubTask()
        self.subtasks.append(subtask)
        subtask.start()
    }
    
    func finish() {
        self.subtasks.last!.stop()
        
        print("Finish Fitts Task")
        print("Total: \(self.subtasks.count) subtasks")
        print("Duration: \(self.duration) secs")
        print("Misses: \(self.misses) misses")
    }
    
    func clear() {
        self.subtasks.removeAll()
    }
}

class FittsSubTask {
    var path = [NSPoint]()
    var startTime: NSTimeInterval!
    var stopTime: NSTimeInterval!
    var elapsedTime: NSTimeInterval!
    var misses: Int = 0
    
    func start() {
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
    }
    
    func stop() {
        self.stopTime = NSDate.timeIntervalSinceReferenceDate()
        self.elapsedTime = self.stopTime - self.startTime
    }
}