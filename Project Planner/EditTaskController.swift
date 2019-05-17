//
//  EditTaskController.swift
//  Project Planner
//
//  Created by user153807 on 4/30/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class EditTaskController : UIViewController{
    // Notes for the task
    @IBOutlet weak var notesTextField: UITextView!
    
    // Name of the task
    @IBOutlet weak var taskNameText: UITextField!
    
    // The task progress
    @IBOutlet weak var progressSlider: UISlider!
    
    // The label to display progress value
    @IBOutlet weak var progressLabel: UILabel!
    
    // The task start date
    @IBOutlet weak var startDatePicker: UIDatePicker!
    
    // Whether a notification should be set
    @IBOutlet weak var reminderSwitch: UISwitch!
    
    // The task due date
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    
    // Application context to save values
    let appContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // The task to edit
    var taskItem : Task?
    
    // The detail controller to allow reloading of tasks once edited
    var delegate: DetailViewController!
    
    // Populate popup fields on load
    override func viewDidLoad() {
        super.viewDidLoad()
        if super.viewIfLoaded != nil{
            if let taskItem = taskItem{
                notesTextField.text = taskItem.notes
                taskNameText.text = taskItem.name
                progressSlider.value = Float(taskItem.progress.description) ?? 0.00
                reminderSwitch.isOn = taskItem.hasReminder
                progressLabel.text = String(taskItem.progress.description ) + "%"
                
                if let dueDate = taskItem.dueDate{
                    dueDatePicker.date = dueDate
                }
                
                if let startDate = taskItem.startDate{
                    startDatePicker.date = startDate
                }
                
                dueDatePicker.backgroundColor = UIColor.gray
                startDatePicker.backgroundColor = UIColor.gray
            }
            
            self.view.layer.borderColor = UIColor.white.cgColor
            self.view.layer.borderWidth = 3
                
        }
    }
    
    // Save the edited task and recreate notifications
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
        if let taskItem = taskItem{
            if let project = taskItem.task_to_project{
                if let dueDate = project.dueDate{
                    if taskNameText.text == nil || taskNameText.text == "" {
                        let alert = UIAlertController(title: "Task name missing",message: "A task name is required to update a task",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    if Calendar.current.startOfDay(for: dueDatePicker.date) < Calendar.current.startOfDay(for: Date.init()){
                        let alert = UIAlertController(title: "Incorrect date",message: "The due date cannot be before today",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    if Calendar.current.startOfDay(for: startDatePicker.date) < Calendar.current.startOfDay(for: Date.init()){
                        let alert = UIAlertController(title: "Incorrect date",message: "The start date cannot be before today",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    if Calendar.current.startOfDay(for: dueDatePicker.date) > Calendar.current.startOfDay(for: dueDate) {
                        let alert = UIAlertController(title: "Incorrect date",message: "The due date cannot be after the project due date",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                
                    if Calendar.current.startOfDay(for: startDatePicker.date) > Calendar.current.startOfDay(for: dueDate){
                        let alert = UIAlertController(title: "Incorrect date",message: "The start date cannot be after the project due date",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    if Calendar.current.startOfDay(for: startDatePicker.date) > Calendar.current.startOfDay(for: dueDatePicker.date){
                        let alert = UIAlertController(title: "Incorrect date",message: "The start date cannot be after the due date",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                }
                
                
                taskItem.dueDate = dueDatePicker.date
                taskItem.name = taskNameText.text
                
                if taskItem.hasReminder == true && self.reminderSwitch.isOn == false{
                    // remove reminder
                    RemoveNotification()
                }
                else if taskItem.hasReminder == false && self.reminderSwitch.isOn == true{
                    // add notification
                    AddNotification()
                    
                }
                else if taskItem.hasReminder == true && reminderSwitch.isOn == true{
                    // Remove existing notification and add updated one
                    RemoveNotification()
                    AddNotification()
                }
                
                taskItem.notes = notesTextField.text
                taskItem.progress = Int16(progressSlider.value)
                taskItem.hasReminder = reminderSwitch.isOn
                taskItem.startDate = startDatePicker.date
                
                
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                
                delegate.tableView.reloadData()
                
                dismiss(animated: true
                    , completion: nil)
            }
        }
    }
    
    // Cancels editing the task and closes the popup
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
        dismiss(animated: true
            , completion: nil)
    }
    
    // Sets the progress label value when the slider value changes
    @IBAction func ProgressSlider_OnChange(_ sender: UISlider) {
        let progress = sender.value
        progressLabel.text = String(Int16(progress)) + "% progress"
    }
    
    // Removes a task notification
    func RemoveNotification(){
        let center = UNUserNotificationCenter.current()
        
        if let taskItem = taskItem, let dayReminder = taskItem.dayReminder{
            center.removePendingNotificationRequests(withIdentifiers: [dayReminder.uuidString])
        }
    }
    
    // Adds a task notification
    func AddNotification(){
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
            if granted{
                if let taskItem = self.taskItem{
                    let dayContent = UNMutableNotificationContent()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    
                    dayContent.title = "A task is getting near the deadline"
                    
                    var projectName = "N/A"
                    
                    if let project = taskItem.task_to_project{
                        projectName = project.name ?? "N/A"
                    }
                    
                    if let name = taskItem.name{
                        dayContent.body = name + " belonging to the project "
                    }
                    
                    dayContent.body += projectName + " has passed the due date: "
                    
                    if let dueDate = taskItem.dueDate{
                        dayContent.body += formatter.string(from: dueDate)
                    
                    
                        dayContent.categoryIdentifier = "alarm"
                        dayContent.sound = UNNotificationSound.default
                        
                        let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day), from: dueDate)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                        let dayId = UUID()
                        let dayRequest = UNNotificationRequest(identifier: dayId.uuidString, content: dayContent, trigger: trigger)
                        center.add(dayRequest, withCompletionHandler: { error in
                            if let error = error {
                                //handle error
                                let alert = UIAlertController(title: "Error",message: error.localizedDescription, preferredStyle: .alert)
                                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(OKAction)
                                self.present(alert, animated: true, completion: nil)
                                return
                            } else {
                                //notification set up successfully
                                taskItem.dayReminder = dayId
                            }
                        })
                    }
                    else{
                        return
                    }
                }
            }
        })
    }
}
