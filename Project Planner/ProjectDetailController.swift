//
//  ProjectDetailController.swift
//  Project Planner
//
//  Created by user153807 on 4/28/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit

class ProjectDetailController :UIViewController {
    @IBOutlet weak var createdOnLabel: UILabel!
    @IBOutlet weak var dueOnLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var progressCircle: CircularProgressBar!
    @IBOutlet weak var daysLeftCircle: CircularProgressBar!
    @IBOutlet weak var notesTextBox: UITextView!
    @IBOutlet weak var projectTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (super.viewIfLoaded != nil && projectItem != nil) {
            self.notesTextBox.layer.borderColor = UIColor.lightGray.cgColor
            self.notesTextBox.layer.borderWidth = 1
            if let project = projectItem{
                PopulateFields()
            }
        }
        else{
            return;
        }
    }
    
    func PopulateFields(){
        if let project = projectItem{
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            projectTitleLabel.text = project.name
            createdOnLabel.text = formatter.string(from: (project.createdDate)!)
            dueOnLabel.text = formatter.string(from: (project.dueDate)!)
            priorityLabel.text = (project.priority == 0 ? "low" : (project.priority == 1 ? "medium" : "high"))
            
            notesTextBox.text = project.notes
            
            let tasks = project.project_to_task?.allObjects as! [Task]
            var progress = 0
            
            if (tasks.count > 0){
                for task in tasks{
                    progress += Int(task.progress)
                }
                if (progress > 0){
                    progress = progress/tasks.count
                }
            }
            
            let progressD = Double(progress)/100
            
            progressCircle.safePercent = 70
            progressCircle.lineWidth = 10
            progressCircle.setProgress(to: progressD, withAnimation: true)
            progressCircle.labelSize = 20
            
            let totalDays = Calendar.current.dateComponents([.day], from: project.createdDate!, to: project.dueDate!)
            
            let daysPassed = Calendar.current.dateComponents([.day], from: project.createdDate!, to: Date.init())
            
            let totalDaysInt = totalDays.day!
            let daysPassedInt = daysPassed.day!
            let days = totalDaysInt - daysPassedInt
            var percentage = 0
            
            if (totalDaysInt != 0){
                percentage = (daysPassedInt/totalDaysInt) * 100
            }
            
            let daysLeft = Double(percentage)
            
            daysLeftCircle.safePercent = 70
            daysLeftCircle.lineWidth = 10
            daysLeftCircle.setProgress(to: daysLeft, withAnimation: true)
            daysLeftCircle.labelSize = 20
            daysLeftCircle.isDays = true
            daysLeftCircle.days = days
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let editProjectController = segue.destination as? EditProjectController,
            segue.identifier == "editProjectPopover"{
            editProjectController.projectItem = self.projectItem
        }
    }
    
    func UpdateProjectItem(newProject:Project){
        projectItem = newProject
        PopulateFields()
    }
    
    func RefreshProgressCircle(){
        let tasks = projectItem?.project_to_task?.allObjects as! [Task]
        var progress = 0
        
        if (tasks.count > 0){
            for task in tasks{
                progress += Int(task.progress)
            }
            if (progress > 0){
                progress = progress/tasks.count
            }
        }
        
        let progressD = Double(progress)/100
        
        progressCircle.safePercent = 70
        progressCircle.lineWidth = 10
        progressCircle.setProgress(to: progressD, withAnimation: true)
        progressCircle.labelSize = 20
    }
    
    var projectItem: Project?
}
