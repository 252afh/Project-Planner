//
//  MasterViewController.swift
//  Project Planner
//
//  Created by user153807 on 4/27/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import UIKit
import CoreData
import EventKit
import UserNotifications

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // The detail view used to show the project information and related tasks
    var detailViewController: DetailViewController? = nil
    
    // The managed object context
    var managedObjectContext: NSManagedObjectContext? = nil

    // Handles the master view loading and sets the initial selected item
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = editButtonItem
        if tableView.numberOfRows(inSection: 0) > 0{
            let initialIndexPath = IndexPath(row: 0, section: 0)
            self.tableView.selectRow(at: initialIndexPath, animated: true, scrollPosition:UITableView.ScrollPosition.none)
            selectTableIndex(index: initialIndexPath)
            
            self.performSegue(withIdentifier: "showDetail", sender: initialIndexPath)
            
            let cell = tableView.cellForRow(at: initialIndexPath)
            let color = UIView()
            color.backgroundColor = UIColor.darkGray
            cell?.selectedBackgroundView = color
        }
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewObject(_ sender: Any) {
        let context = self.fetchedResultsController.managedObjectContext
        

        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // MARK: - Segues
    // Handles segues to other views
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.projectItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                self.detailViewController = controller
            }
        }
        
        if let addProjectController = segue.destination as? AddProjectController,
            segue.identifier == "AddProject"{
            addProjectController.delegate = self
        }

    }
    
    // Handles selecting the given table index
    func selectTableIndex(index: IndexPath){
        DispatchQueue.main.async {
            self.tableView.selectRow(at: index, animated: true, scrollPosition: UITableView.ScrollPosition.none)
            self.tableView(self.tableView, didSelectRowAt: index)
            let projectItem = self.fetchedResultsController.object(at: index)
            self.detailViewController?.projectItem = projectItem
            self.detailViewController?.projectController?.UpdateProjectItem(newProject: projectItem)
        }
    }
    
    // Handles highlighting the selected table index
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath)
        let color = UIView()
        color.backgroundColor = UIColor.darkGray
        cell?.selectedBackgroundView = color
    }

    // MARK: - Table View
    // Returns the number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    // REturns the number of rows in the given section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    // Returns the cell at the given index
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let project = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withProject: project)
        return cell
    }

    // Allows rows to be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Handles editing cells, mainly deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            let projectItem = fetchedResultsController.object(at: indexPath) 
            context.delete(projectItem)
            let eventStore = EKEventStore()
            let calendars = eventStore.calendars(for: .event)
            let tasks = projectItem.project_to_task?.allObjects as! [Task]
            
            if tasks.count > 0{
                let center = UNUserNotificationCenter.current()
                
                for task in tasks{
                    if let dayReminder = task.dayReminder{
                        center.removePendingNotificationRequests(withIdentifiers: [dayReminder.uuidString])
                    }
                }
            }
            
            for calendar in calendars{
                if calendar.title == "Project_Planner"{
                    if let dueDate = projectItem.dueDate{
                        let pastPredicate = eventStore.predicateForEvents(withStart: dueDate, end: dueDate, calendars: [calendar])
                        
                        let events = eventStore.events(matching: pastPredicate)
                        for foundReminders in events{
                            if let calendarId = projectItem.calenderId{
                                if foundReminders.calendarItemIdentifier == calendarId.uuidString{
                                    let remindersToDelete = true
                                    let span = EKSpan(rawValue: 0)
                                    do {
                                        try eventStore.remove(foundReminders, span: span!, commit: false)
                                    }
                                    catch {
                                        
                                    }
                                    if remindersToDelete {
                                        do {
                                            try eventStore.commit()
                                        }
                                        catch {
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            selectTableIndex(index: IndexPath(row: 0, section: 0))
        }
    }

    // Configures the table cell with the correct information
    func configureCell(_ cell: UITableViewCell, withProject project: Project) {
        cell.textLabel!.text = project.name
        cell.detailTextLabel!.text = (project.priority == 0 ? "low" : (project.priority == 1 ? "medium" : "high"))
    }

    // MARK: - Fetched results controller
    
    // Handles the fetched results
    var fetchedResultsController: NSFetchedResultsController<Project> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Project>? = nil

        // Starts table content being edited
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if tableView.numberOfRows(inSection: 0) > 0{
            tableView.beginUpdates()
        }
    }

    // Handles adding and deleting table sections
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    // Handles editing of the fetched controller information
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
                tableView.selectRow(at: newIndexPath, animated: true, scrollPosition: UITableView.ScrollPosition(rawValue: 0)!)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withProject: anObject as! Project)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withProject: anObject as! Project)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    // Hanldes ending the controller changes
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if tableView.numberOfRows(inSection: 0) > 0{
            tableView.endUpdates()
        }
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}

