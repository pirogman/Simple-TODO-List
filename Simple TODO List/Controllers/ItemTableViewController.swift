//
//  ItemTableViewController.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 01.04.2021.
//

import UIKit
import CoreData
import TableFlip
import TableViewDragger
import SwipeCellKit
import ChameleonFramework

class ItemTableViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let container = AppDelegate.current!.persistentContainer
    private var dragger: TableViewDragger!
    private var isDragging = false
    
    var category: Category!
    
    private var mainColor: UIColor { return UIColor(hexString: category.colorHex!)! }
    private var secondaryColor: UIColor { return mainColor.darken(byPercentage: 0.4)! }
    
    private let loadAnimation = TableViewAnimation.Cell.left(duration: 0.6)
    private let searchAnimation = TableViewAnimation.Cell.custom(duration: 0.6, transform: CGAffineTransform(translationX: 8, y: 8), options: .curveEaseInOut)
    
    private var isSearching = false
    
    private var items = [[Item]]()
    
    private var allItems: [Item] {
        var array = [Item]()
        items.forEach() { array += $0 }
        return array.sorted { $0.priority > $1.priority }
    }
    
    private var maxPriority: Int {
        return Int(allItems.first?.priority ?? 0 )
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        let contrastColor = ContrastColorOf(mainColor, returnFlat: true)
        let isContrastWhite = contrastColor == ContrastColorOf(.black, returnFlat: true)
        return isContrastWhite ? .lightContent : .darkContent
    }
    
    // MARK: - ViewController Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dragger = TableViewDragger(tableView: tableView)
        dragger.dataSource = self
        dragger.delegate = self
        dragger.availableHorizontalScroll = true
        dragger.alphaForCell = 0.85
        dragger.zoomScaleForCell = 0.85
        dragger.opacityForShadowOfCell = 0.0
        
        tableView.backgroundColor = mainColor
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 0
        tableView.allowsSelection = false
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadData()
        reloadData(animatedBy: loadAnimation)
        
        container.undoManager.removeAllActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
        
        title = category.name
        
        let contrast = ContrastColorOf(mainColor, returnFlat: true)
        searchBar.backgroundColor = mainColor
        searchBar.barTintColor = mainColor
        searchBar.tintColor = contrast
        
        let isContrastWhite = contrast == ContrastColorOf(.black, returnFlat: true)
        let sfBack: UIColor = !isContrastWhite
            ? mainColor.darken(byPercentage: 0.2)!
            : mainColor.lighten(byPercentage: 0.2)!
        let sfFront: UIColor = ContrastColorOf(sfBack, returnFlat: true)
        searchBar.searchTextField.backgroundColor = sfBack
        searchBar.searchTextField.tokenBackgroundColor = .red
        searchBar.searchTextField.tintColor = sfFront
        searchBar.searchTextField.textColor = sfFront
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        
        if let navBar = navigationController?.navigationBar {
            navBar.backgroundColor = mainColor
            navBar.barTintColor = mainColor
            
            navBar.tintColor = contrast
            navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: contrast]
        }
        
        clearUndoStack()
    }
    
    // MARK: - Shake to Undo
    
    private let undoer = UndoManager()
    
    override var undoManager: UndoManager? {
        return undoer
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake && !isDragging else { return }
        
        if undoManager?.canUndo ?? false {
            undoManager?.undo()
        } else {
            print(" ! Nothing to undo")
        }
    }
    
    private func clearUndoStack() {
        container.undoManager.removeAllActions()
        undoer.removeAllActions()
    }
    
    // MARK: - Data Manipulating
    
    private func showDateAlert(_ text: String? = nil, date: Date? = nil, action: ((String?, Date?) -> Void)?, actionTitle: String) {
        let storyboard = UIStoryboard(name: "Alert", bundle: .main)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "DateAlertVC") as! DateAlertViewController
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        alertVC.action = action
        alertVC.initialText = text
        alertVC.initialDate = date
        alertVC.actionTitle = actionTitle
        present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func addButtonTap(_ sender: UIBarButtonItem) {
        // No adding while searching
        guard !isSearching else { return }
        
        // Show custom alert
        showDateAlert(action: addItem(named:dueDate:), actionTitle: "Add")
    }
    
    private func addItem(named name: String?, dueDate: Date? = nil) {
        // Ensure there is a name after all
        var safeName = name ?? "Nil Name"
        safeName = safeName.trimmingCharacters(in: .whitespaces)
        safeName = safeName.isEmpty ? "Empty Name" : safeName
        
        // Create new item
        let newItem = container.createItem(for: category, name: safeName, priority: Int16(maxPriority + 1), dueDate: dueDate)
        saveData()
        
        // Add new item to array
        items[0].insert(newItem, at: 0)
        
        // Insert item to table view
        let newPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [newPath], with: .top)
        
        // Also update gradient
        reloadData()
        
        // Undo creating item
        undoManager?.registerUndo(withTarget: self, handler: { (table) in
            table.deleteItem(newItem)
            table.saveData()
            table.items[0].remove(at: 0)
            table.tableView.deleteRows(at: [newPath], with: .top)
        })
    }
    
    private func editItem(_ item: Item, at indexPath: IndexPath, name: String? = nil, priority: Int16? = nil, isCompleted: Bool? = nil, dueDate: Date? = nil) {
        // Undo editing item
        let oldName = item.name
        let oldPriority = item.priority
        let oldCompleted = item.isCompleted
        let oldDue = item.dueDate
        undoManager?.registerUndo(withTarget: self, handler: { (table) in
            item.name = oldName
            item.priority = oldPriority
            item.isCompleted = oldCompleted
            item.dueDate = oldDue
            table.saveData()
            
            // Reload just in case huge changes happened
            table.reloadData(animatedBy: table.searchAnimation)
        })
        
        // Update fields
        item.name = name ?? item.name
        item.priority = priority ?? item.priority
        item.isCompleted = isCompleted ?? item.isCompleted
        item.dueDate = dueDate
        saveData()
        
        // Reload just in case huge changes happened
        reloadData(animatedBy: searchAnimation)
    }
    
    private func deleteItem(_ item: Item) {
        container.delete(item)
    }
    
    private func saveData() {
        container.saveContext()
    }
    
    private func loadData(searchText: String? = nil) {
        let all = container.fetchItems(of: category, search: searchText)
        items = [all.filter { !$0.isCompleted }]
        items += [all.filter { $0.isCompleted }]
    }

    // MARK: - TableView DataSource & Delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = items[indexPath.section][indexPath.row].dueDate == nil
            ? "BasicItemCell"
            : "SubtitleItemCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        updateCell(cell, at: indexPath)
        
        if let swipeCell = cell as? SwipeTableViewCell {
            swipeCell.delegate = self
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - Cell Appearance Update
    
    private func updateCell(at indexPath: IndexPath) {
        updateCell(tableView.cellForRow(at: indexPath)!, at: indexPath)
    }
    
    private func updateCell(_ cell: UITableViewCell) {
        updateCell(cell, at: tableView.indexPath(for: cell)!)
    }
    
    private func updateCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let item = items[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.name!
        if let time = item.dueTime?.getTimeValues() {
            let weeksText = time.weeks > 0 ? " \(time.weeks) weeks," : ""
            let daysText = time.days > 0 ? " \(time.days) days," : ""
            let hoursText = time.hours > 0 ? " \(time.hours) hours," : ""
            let minutesText = time.minutes > 0 ? " \(time.minutes) minutes" : ""
            cell.detailTextLabel?.text = time.isValid
                ? "Due in" + weeksText + daysText + hoursText + minutesText + "."
                : item.isCompleted ? "Due date passed." : "Due date missed!"
        } else {
            cell.detailTextLabel?.text = "No due date."
        }
        
        // Colors
        let darkenStep = 0.4 / CGFloat(max(items[indexPath.section].count, 7) + 3)
        let darkenScale = darkenStep * CGFloat(indexPath.row + 1)
        let backColor = (item.isCompleted ? secondaryColor : mainColor).darken(byPercentage: darkenScale)!
        let contrast = ContrastColorOf(item.isCompleted ? secondaryColor : mainColor, returnFlat: true)
        cell.backgroundColor = backColor
        cell.textLabel?.textColor = contrast
        cell.detailTextLabel?.textColor = contrast
        cell.tintColor = contrast
        
        // Custom accessory type
        if item.isOverdue && !item.isCompleted {
            let image = UIImage(systemName: "exclamationmark.triangle.fill")
            let accessory  = UIImageView(frame:CGRect(x:0, y:0, width:(image?.size.width)!, height:(image?.size.height)!))
            accessory.image = image
            accessory.tintColor = contrast
            cell.accessoryView = accessory
        } else {
            cell.accessoryView = nil
            cell.accessoryType = item.isCompleted ? .checkmark : .none
        }
    }
    
    // MARK: - TableView ReloadData Animation
    
    private func reloadData() {
        tableView.reloadData()
    }
    
    private func reloadData(animatedBy animation: TableViewAnimation.Table) {
        tableView.reloadData()
        tableView.animate(animation: animation)
    }
    
    private func reloadData(animatedBy animation: TableViewAnimation.Cell) {
        tableView.reloadData()
        tableView.animate(animation: animation)
    }
    
}

// MARK: - TableViewDragger

extension ItemTableViewController: TableViewDraggerDelegate, TableViewDraggerDataSource {
    
    func dragger(_ dragger: TableViewDragger, moveDraggingAt indexPath: IndexPath, newIndexPath: IndexPath) -> Bool {
        // Get items in action
        let draggedItem = items[indexPath.section][indexPath.row]
        let referenceItem = items[newIndexPath.section][newIndexPath.row]
        
        // Update items priorities
        let currentItems = allItems
        let draggedIndex = currentItems.firstIndex(of: draggedItem)!
        let referenceIndex = currentItems.firstIndex(of: referenceItem)!
        let newPriority = referenceItem.priority
        if draggedIndex > referenceIndex {
            // Dragged up
            for i in referenceIndex...draggedIndex {
                currentItems[i].priority -= Int16(1)
                
                // Undo priority change
                undoManager?.registerUndo(withTarget: self, handler: { (table) in
                    currentItems[i].priority += Int16(1)
                })
            }
        } else {
            // Dragged down
            for i in draggedIndex...referenceIndex {
                currentItems[i].priority += Int16(1)
                
                // Undo priority change
                undoManager?.registerUndo(withTarget: self, handler: { (table) in
                    currentItems[i].priority -= Int16(1)
                })
            }
        }
        
        // Change moved item priority
        let oldPriority = draggedItem.priority
        draggedItem.priority = newPriority
        
        // Undo priority change
        undoManager?.registerUndo(withTarget: self, handler: { (table) in
            draggedItem.priority = oldPriority
        })
        
        // Move rows
        items[indexPath.section].remove(at: indexPath.row)
        items[newIndexPath.section].insert(draggedItem, at: newIndexPath.row)
        tableView.moveRow(at: indexPath, to: newIndexPath)
        
        // Undo mowing
        undoManager?.registerUndo(withTarget: self, handler: { (table) in
            table.items[newIndexPath.section].remove(at: newIndexPath.row)
            table.items[indexPath.section].insert(draggedItem, at: indexPath.row)
            table.tableView.moveRow(at: newIndexPath, to: indexPath)
        })
        
        return true
    }
    
    func dragger(_ dragger: TableViewDragger, didEndDraggingAt indexPath: IndexPath) {
        // Undo completeness update
        let oldComplete = items[indexPath.section][indexPath.row].isCompleted
        undoManager?.registerUndo(withTarget: self, handler: { (table) in
            table.items[indexPath.section][indexPath.row].isCompleted = oldComplete
            table.saveData()
            
            // Delay table update to fix undo dragging
            DispatchQueue.main.async { table.reloadData() }
        })
        
        // Update completion after drop (possible between sections)
        items[indexPath.section][indexPath.row].isCompleted = indexPath.section == 1
        saveData()
        reloadData()
        isDragging = false
        undoManager?.endUndoGrouping()
    }
    
    func dragger(_ dragger: TableViewDragger, didBeginDraggingAt indexPath: IndexPath) {
        isDragging = true
        undoManager?.beginUndoGrouping()
    }
    
    func dragger(_ dragger: TableViewDragger, shouldDragAt indexPath: IndexPath) -> Bool {
        // No reordering while searching
        return !isSearching
    }
    
}

// MARK: - SwipeTableViewCellDelegate

extension ItemTableViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        // Block actions while dragging
        guard !isDragging else { return nil }
        
        switch orientation {
        case .left:
            // Done/undone action
            let actionTitle = indexPath.section == 0 ? "Done" : "Undone"
            let done = SwipeAction(style: .default, title: actionTitle) {
                [unowned self] (action, path) in
                // Get selected item (remove from current items sub array) & save data
                let item = items[path.section].remove(at: path.row)
                item.isCompleted = !item.isCompleted
                saveData()
                
                // Insert selected item to another section (another items sub array)
                let newSection = item.isCompleted ? 1 : 0
                items[newSection].append(item)
                items[newSection] = items[newSection].sorted { $0.priority > $1.priority }
                let newRow = items[newSection].firstIndex(of: item)!
                
                // Animate item moving
                let newIndexPath = IndexPath(row: newRow, section: newSection)
                tableView.moveRow(at: path, to: newIndexPath)
                
                // Update gradient
                reloadData()
                
                // Undo done/undone
                undoManager?.registerUndo(withTarget: self, handler: { (table) in
                    table.items[newSection].remove(at: newRow)
                    item.isCompleted = !item.isCompleted
                    table.saveData()
                    
                    table.items[path.section].append(item)
                    table.items[path.section] = table.items[path.section].sorted { $0.priority > $1.priority }
                    
                    table.tableView.moveRow(at: newIndexPath, to: path)
                    table.reloadData()
                })
            }
            done.backgroundColor = FlatGreen().lighten(byPercentage: 0.15)!
            done.textColor = ContrastColorOf(done.backgroundColor!, returnFlat: true)
            
            // Edit action
            let edit = SwipeAction(style: .default, title: "Edit") {
                [unowned self] (action, path) in
                // Get selected item and edit if needed
                let item = items[path.section][path.row]
                showDateAlert(item.name, date: item.dueDate, action: { (name, dueDate) in
                    editItem(item, at: path, name: name, dueDate: dueDate)
                }, actionTitle: "Edit")
            }
            edit.backgroundColor = FlatGray().lighten(byPercentage: 0.15)!
            edit.textColor = ContrastColorOf(edit.backgroundColor!, returnFlat: true)
            
            return [done, edit]
        case .right:
            let action = SwipeAction(style: .destructive, title: "Remove") {
                [unowned self] (action, path) in
                // Remove item
                let item = items[path.section].remove(at: path.row)
                deleteItem(item)
                saveData()
                
                // Undo removal
                undoManager?.registerUndo(withTarget: self, handler: { (table) in
                    table.container.undoManager.undo() // Undo delete
                    table.saveData()
                    table.items[path.section].insert(item, at: path.row)
                    table.tableView.insertRows(at: [path], with: .left)
                })
            }
            action.backgroundColor = FlatRed().lighten(byPercentage: 0.15)!
            action.textColor = ContrastColorOf(action.backgroundColor!, returnFlat: true)
            return [action]
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        
        options.expansionStyle = orientation == .right ? .destructiveAfterFill : .selection
        options.transitionStyle = .drag
        options.backgroundColor = FlatGreenDark()
        
        return options
    }
    
}

// MARK: - UISearchBarDelegate

extension ItemTableViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text!.isEmpty {
            isSearching = false
            searchItems(with: nil)
        } else {
            isSearching = true
            searchItems(with: searchBar.text!)
        }
        
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            searchItems(with: nil)
            
            // Delay hiding keyboard to handle when 'x' button clicked
            DispatchQueue.main.async { searchBar.resignFirstResponder() }
        } else {
            isSearching = true
            searchItems(with: searchBar.text!)
        }
    }
    
    private func searchItems(with text: String?) {
        let oldCount = allItems.count
        loadData(searchText: text)
        
        if oldCount != allItems.count {
            reloadData(animatedBy: searchAnimation)
        }
    }
    
}
