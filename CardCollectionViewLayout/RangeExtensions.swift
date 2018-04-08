//
//  RangeExtensions.swift
//  CryptoApp
//
//  Created by Michal Štembera on 26/03/2018.
//  Copyright © 2018 NETVOR s.r.o. All rights reserved.
//

import Foundation
import UIKit

extension ClosedRange {
    func clampValue(_ value: Bound) -> Bound {
        return min(upperBound, max(value, lowerBound))
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return range.clampValue(self)
    }
}

extension ClosedRange where Bound == CGFloat {
    var lengthRange: ClosedRange {
        return 0...(upperBound - lowerBound)
    }
}
