//
//  DetailViewController.swift
//  Project Planner
//
//  Created by user153807 on 4/27/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // The tableview to show tasks
    @IBOutlet weak var tableView: UITableView!
    
    // The tasks shown in the table
    var tasks :[Task]!
    
    // The project controller used to reload the progress circles
    var projectController:ProjectDetailController?
    
    // The project item to display
    var projectItem: Project?
    
    // Sets up the view and loads the tasks
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        if let projectItem = projectItem, let projectObjects = projectItem.project_to_task{
            tasks = (projectObjects.allObjects as? [Task])
        }
    }
    
    // Handles whether the task editing popup should be shown if no project is loaded
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "taskPopOverSegue"{
            if projectItem == nil{
                return false
            }
        }
        
        return true
    }
    
    // Handles sugues to other views
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let projectController = segue.destination as? ProjectDetailController,
            segue.identifier == "projectEmbedSegue"{
            projectController.projectItem = self.projectItem
            self.projectController = projectController
        }
        
        if let taskController = segue.destination as? AddTaskController,
            segue.identifier == "taskPopOverSegue"{
            taskController.delegate = self
            taskController.projectItem = self.projectItem
        }
        
        if let editTaskController = segue.destination as? EditTaskController,
            segue.identifier == "editTaskPopup"{
            if let cell = sender as? CustomTableCell{
                editTaskController.taskItem = cell.task
                editTaskController.delegate = self
            }
        }
    }
    
    // Reloads the task table data
    func ReloadTasks(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // Refreshes the project circles information
    func RefreshProjectProgress(){
        if let projectController = projectController{
            projectController.RefreshProgressCircles()
        }
    }
    
    // Handles a row being selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? CustomTableCell{
            self.performSegue(withIdentifier: "editTaskPopup", sender: cell)
            let color = UIView()
            color.backgroundColor = UIColor.darkGray
            cell.selectedBackgroundView = color
        }
    }
    
    // Returns number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Returns number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tasks = tasks{
            return tasks.count
        }
        
        return 0
    }
    
    // Handles populating a table cell with the correct information
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",for: indexPath) as! CustomTableCell
        if let tasks = tasks{
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            let task = tasks[indexPath.row]
            cell.task = task
            
            if let dueDate = task.dueDate{
                cell.dueDateLabel.text = formatter.string(from: dueDate)
            }
            
            cell.nameLabel.text = task.name
            cell.noteText.text = task.notes
            cell.noteText.layer.borderColor = UIColor.lightGray.cgColor
            cell.noteText.layer.borderWidth = 1
            
            if let startDate = task.startDate{
                cell.startDateLabel.text = formatter.string(from: startDate)
            }
            
            let progressD = Double(task.progress)/100
                
            cell.progressCircle.safePercent = 70
            cell.progressCircle.lineWidth = 10
            cell.progressCircle.setProgress(to: progressD, withAnimation: true)
            cell.progressCircle.labelSize = 20
        }
        
        return cell
    }

    // Allows table rows to be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Handles a task being deleted
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if let cell = tableView.cellForRow(at: indexPath) as? CustomTableCell{
                if let object = cell.task{
                    tasks!.remove(at: indexPath.row)
                    
                    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                    context.delete(object)
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    
                    tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                    let center = UNUserNotificationCenter.current()
                    if let reminderId = object.dayReminder{
                        center.removePendingNotificationRequests(withIdentifiers: [(reminderId.uuidString)])
                    }
                }
                
                RefreshProjectProgress()
            }
        }
    }
}
