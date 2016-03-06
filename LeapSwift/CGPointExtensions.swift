//
//  CGPointExtensions.swift
//  LeapSwift
//
//  Created by Huai-Che Lu on 3/5/16.
//  Copyright © 2016 Huai-Che Lu. All rights reserved.
//

import Foundation

extension CGPoint {
    func distanceToPoint(point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        
        return sqrt((dx * dx) + (dy * dy))
    }
}