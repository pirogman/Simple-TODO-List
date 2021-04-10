//
//  Category+Extensions.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 05.04.2021.
//

import CoreData

enum CategoryItemsFilterRule {
    case completed, uncompleted, pastDueDate
}

extension Category {
    
    /// Returns a sorted array of items in the category. No filter applied by default
    func getItems(filterRule: CategoryItemsFilterRule? = nil) -> [Item] {
        guard let itemsSet = items else { return [] }
        
        // Get sorted array of Items
        var array = [Item]()
        itemsSet.forEach { array.append($0 as! Item) }
        array = array.sorted { $0.priority > $1.priority }
        
        // Apply filters if needed
        guard let rule = filterRule else { return array }
        switch rule {
        case .completed:
            return array.filter { $0.isCompleted }
            
        case .uncompleted:
            return array.filter { !$0.isCompleted }
            
        case .pastDueDate:
            return array.filter { !$0.isCompleted && $0.isOverdue }
        }
    }
    
}
