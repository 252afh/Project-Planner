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
    @IBOutlet weak var tableView: UITableView!
    var itemList = [String]()
    var tasks :[Task]?
    var projectController:ProjectDetailController?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        if projectItem != nil {
            tasks = projectItem?.project_to_task?.allObjects as! [Task]
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "taskPopOverSegue"{
            if projectItem == nil{
                return false
            }
        }
        
        return true
    }
    
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
                let cell = sender as? CustomTableCell
                editTaskController.taskItem = cell?.task
        }
    }
    
    func ReloadTasks(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func RefreshProjectProgress(){
        projectController?.RefreshProgressCircle()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? CustomTableCell
        self.performSegue(withIdentifier: "editTaskPopup", sender: cell)
        
        let color = UIView()
        color.backgroundColor = UIColor.darkGray
        cell?.selectedBackgroundView = color
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",for: indexPath) as! CustomTableCell
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let task = tasks![indexPath.row]
        cell.task = task
        cell.dueDateLabel.text = formatter.string(from: task.dueDate!)
        cell.nameLabel.text = task.name
        cell.noteText.text = task.notes
        cell.noteText.layer.borderColor = UIColor.lightGray.cgColor
        cell.noteText.layer.borderWidth = 1
        cell.startDateLabel.text = formatter.string(from: task.startDate!)
        let progressD = Double(task.progress)/100
        
        cell.progressCircle.safePercent = 70
        cell.progressCircle.lineWidth = 10
        cell.progressCircle.setProgress(to: progressD, withAnimation: true)
        cell.progressCircle.labelSize = 20
        
        return cell
    }


    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let cell = tableView.cellForRow(at: indexPath) as? CustomTableCell
            let object = cell?.task
            tasks?.remove(at: indexPath.row)
            
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            context.delete(object!)
            //context.delete(object)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [(object?.dayReminder!.uuidString)!])
        }
    }

    var projectItem: Project?


}

