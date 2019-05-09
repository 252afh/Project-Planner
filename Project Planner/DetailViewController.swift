//
//  DetailViewController.swift
//  Project Planner
//
//  Created by user153807 on 4/27/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var itemList = [String]()
    var tasks :[Task]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        if projectItem != nil {
            tasks = projectItem?.project_to_task?.allObjects as! [Task]
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let projectController = segue.destination as? ProjectDetailController,
            segue.identifier == "projectEmbedSegue"{
            projectController.projectItem = self.projectItem
        }
        
        if let taskController = segue.destination as? AddTaskController,
            segue.identifier == "taskPopOverSegue"{
            taskController.projectItem = self.projectItem
        }
        
        if let editTaskController = segue.destination as? EditTaskController,
            segue.identifier == "editTaskPopup"{
                let cell = sender as? CustomTableCell
                editTaskController.taskItem = cell?.task
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? CustomTableCell
        self.performSegue(withIdentifier: "editTaskPopup", sender: cell)
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
        cell.progressLabel.text =  String(task.progress) + "%"
        cell.progressSlider.value = Float(task.progress)
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
        }
    }

    var projectItem: Project?


}

