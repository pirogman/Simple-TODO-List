//
//  Item+Extensions.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 05.04.2021.
//

import CoreData

extension Item {
    
    /// Returns `true` when due date is set in the past. Returns `false` when due date not set
    var isOverdue: Bool {
        return dueTime ?? 1 < 0
    }
    
    /// Returns overdue time in seconds if possible. Negative values mean that due time is in the future
    var overdueTime: TimeInterval? {
        return dueDate?.distance(to: Date())
    }
    
    /// Returns due time in seconds if possible. Negative values mean that due time is in the past
    var dueTime: TimeInterval? {
        guard let due = dueDate else { return nil }
        return Date().distance(to: due)
    }
    
}
