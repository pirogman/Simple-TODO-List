//
//  PersistentContainer.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 02.04.2021.
//

import UIKit
import CoreData

class PersistentContainer: NSPersistentContainer {
    
    let undoManager: UndoManager
    
    override init(name: String, managedObjectModel model: NSManagedObjectModel) {
        undoManager = UndoManager()
        
        super.init(name: name, managedObjectModel: model)
        
        viewContext.undoManager = undoManager
    }
    
    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print(" ! Error saving context: \(error)")
        }
    }
    
    // MARK: - Delete Data
    
    func delete(_ item: Item) {
        viewContext.delete(item)
        
        undoManager.registerUndo(withTarget: viewContext) { (context) in
            context.insert(item)
        }
    }
    
    func delete(_ category: Category) {
        let categoryItems = fetchItems(of: category)
        categoryItems.forEach { viewContext.delete($0) }
        viewContext.delete(category)
        
        undoManager.registerUndo(withTarget: viewContext) { (context) in
            context.insert(category)
            categoryItems.forEach {
                $0.category = category
                context.insert($0)
            }
        }
    }
    
    // MARK: - Date Creation
    
    @discardableResult func createCategory(name: String, priority: Int16, colorHex: String, creationDate: Date = Date()) -> Category {
        let newCategory = Category(context: viewContext)
        newCategory.name = name
        newCategory.priority = priority
        newCategory.creationDate = creationDate
        newCategory.colorHex = colorHex
        
        undoManager.registerUndo(withTarget: viewContext) { (context) in
            context.delete(newCategory)
        }
        
        return newCategory
    }
    
    @discardableResult func createItem(for category: Category, name: String, priority: Int16, isCompleted: Bool = false, creationDate: Date = Date(), dueDate: Date? = nil) -> Item {
        let newItem = Item(context: viewContext)
        newItem.name = name
        newItem.isCompleted = isCompleted
        newItem.priority = priority
        newItem.creationDate = creationDate
        newItem.dueDate = dueDate
        newItem.category = category
        
        undoManager.registerUndo(withTarget: viewContext) { (context) in
            context.delete(newItem)
        }
        
        return newItem
    }
    
    // MARK: - Demo
    
    func createTutorialCategory(colorHex hex: String) -> Category {
        let tutorial = createCategory(name: "Tutorial", priority: 0, colorHex: hex)
        
        createItem(for: tutorial, name: "Full swipe to the right to complete", priority: 11)
        createItem(for: tutorial, name: "Full swipe to the left to delete", priority: 10)
        createItem(for: tutorial, name: "A completed one", priority: 9, isCompleted: true)
        createItem(for: tutorial, name: "Tap and hold to pick up", priority: 8)
        createItem(for: tutorial, name: "Move items anywhere", priority: 7)
        createItem(for: tutorial, name: "Add new items at '+' sign", priority: 6)
        createItem(for: tutorial, name: "Create items with due date", priority: 5, dueDate: Date().addingTimeInterval(TimeInterval.day))
        createItem(for: tutorial, name: "Easily identify overdue ones", priority: 4, dueDate: Date().addingTimeInterval(-TimeInterval.hour))
        createItem(for: tutorial, name: "Completed it time", priority: 3, isCompleted: true, dueDate: Date().addingTimeInterval(TimeInterval.hour * 6))
        createItem(for: tutorial, name: "Edit items by light left swipe", priority: 2)
        createItem(for: tutorial, name: "Try shaking to undo any action", priority: 1)
        
        return tutorial
    }
    
    // MARK: - Fetching Data
    
    func fetchCategories() -> [Category] {
        var result = [Category]()
        do {
            let request: NSFetchRequest = Category.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
            result = try viewContext.fetch(request)
        } catch {
            print(" ! Error fetching categories: \(error)")
        }
        return result
    }
    
    func fetchItems(of category: Category, search: String? = nil) -> [Item] {
        var result = [Item]()
        do {
            let request: NSFetchRequest = Item.fetchRequest()
            request.predicate = NSPredicate(format: "category.name MATCHES %@", category.name!)
            if let searchText = search {
                let searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, searchPredicate])
            }
            request.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
            result = try viewContext.fetch(request)
        } catch {
            print(" ! Error fetching categories: \(error)")
        }
        return result
    }
    
}
