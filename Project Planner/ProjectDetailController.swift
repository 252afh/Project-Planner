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
    // Project created date label
    @IBOutlet weak var createdOnLabel: UILabel!
    
    //Project due date label
    @IBOutlet weak var dueOnLabel: UILabel!
    
    // Project priority label
    @IBOutlet weak var priorityLabel: UILabel!
    
    // Project progress visual
    @IBOutlet weak var progressCircle: CircularProgressBar!
    
    // Project days left visual
    @IBOutlet weak var daysLeftCircle: CircularProgressBar!
    
    // Project notes
    @IBOutlet weak var notesTextBox: UITextView!
    
    // Project title label
    @IBOutlet weak var projectTitleLabel: UILabel!
    
    // The project to display in this page
    var projectItem: Project?
    
    // Sets up the fields and populates them on load
    override func viewDidLoad() {
        super.viewDidLoad()
        if (super.viewIfLoaded != nil && projectItem != nil) {
            self.notesTextBox.layer.borderColor = UIColor.lightGray.cgColor
            self.notesTextBox.layer.borderWidth = 1
            PopulateFields()
        }
    }
    
    // Populates the views fields using the project
    func PopulateFields(){
        if let project = projectItem{
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            projectTitleLabel.text = project.name
            
            if let createdDate = project.createdDate{
                createdOnLabel.text = formatter.string(from: createdDate)
            }
            
            if let dueDate = project.dueDate{
                dueOnLabel.text = formatter.string(from: dueDate)
            }
            
            priorityLabel.text = (project.priority == 0 ? "low" : (project.priority == 1 ? "medium" : "high"))
            
            notesTextBox.text = project.notes
            
            RefreshProgressCircles()
        }
    }
    
    // Decides whether the edit popup should show if no project is loaded
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "editProjectPopover"{
            if projectItem == nil{
                return false
            }
        }
        
        return true
    }
    
    // Prepares for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let editProjectController = segue.destination as? EditProjectController,
            segue.identifier == "editProjectPopover"{
            editProjectController.projectItem = self.projectItem
            editProjectController.delegate = self
        }
    }
    
    // Updates the local project item and repopulates the form
    func UpdateProjectItem(newProject:Project?){
        if newProject == nil{
            self.projectTitleLabel.text = "Select a project"
            self.createdOnLabel.text = nil
            self.daysLeftCircle.setProgress(to: 0.00, withAnimation: false)
            self.notesTextBox.text = nil
            self.dueOnLabel.text = nil
            self.priorityLabel.text = nil
            self.progressCircle.setProgress(to: 0.00, withAnimation: false)
            projectItem = nil
        }
        else{
            projectItem = newProject
            PopulateFields()
        }
    }
    
    // Tells the progress circles to reload, used when a task is edited to only reload the relating information or when loading a project
    func RefreshProgressCircles(){
        if let project = projectItem{
            let tasks = project.project_to_task?.allObjects as? [Task]
            
            var progress = 0
            if let tasks = tasks{
                if (tasks.count > 0){
                    for task in tasks{
                        progress += Int(task.progress)
                    }
                    if (progress > 0){
                        progress = progress/tasks.count
                    }
                }
            }
            
            let progressD = Double(progress)/100
            
            progressCircle.safePercent = 70
            progressCircle.lineWidth = 10
            progressCircle.setProgress(to: progressD, withAnimation: true)
            progressCircle.labelSize = 20
            
            var totalDaysInt = 0
            var daysPassedInt = 0
            
            if let createdDate = project.createdDate, let dueDate = project.dueDate{
                let totalDays = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: createdDate), to: Calendar.current.startOfDay(for: dueDate))
                
                let daysPassed = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: createdDate), to: Calendar.current.startOfDay(for: Date.init()))
                
                totalDaysInt = totalDays.day!
                daysPassedInt = daysPassed.day!
                
                
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date.init()), to: Calendar.current.startOfDay(for: dueDate))
                
                if var days = days.day{
                    
                    var percentage = 0.00
                    
                    if totalDaysInt != 0{
                        percentage = Double((Double(daysPassedInt)/Double(totalDaysInt)))
                    }
                    
                    if Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: Date.init()){
                        percentage = 1.00
                        days = totalDaysInt
                    }
                    
                    daysLeftCircle.safePercent = 70
                    daysLeftCircle.lineWidth = 10
                    daysLeftCircle.setProgress(to: percentage, withAnimation: true)
                    daysLeftCircle.labelSize = 40
                    daysLeftCircle.isDays = true
                    daysLeftCircle.days = days
                }
            }
        }
    }
}
