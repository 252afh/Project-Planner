//
//  TaskTableController.swift
//  Project Planner
//
//  Created by user153807 on 4/29/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit

class TaskTableController : UITableViewController{
    var tasks : [Task]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let editTaskController = segue.destination as? EditTaskController,
            segue.identifier == "editTaskPopup"{
            let cell = sender as! CustomTableCell
            editTaskController.taskItem = cell.task
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",for: indexPath) as! CustomTableCell
        //let data = myInternalDataStructure[indexPath.section][indexPath.row]
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let task = tasks![indexPath.row]
        cell.dueDateLabel.text = formatter.string(from: task.dueDate!)
        cell.nameLabel.text = task.name
        return cell
    }
}
