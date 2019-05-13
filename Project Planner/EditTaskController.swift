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
    
    @IBOutlet weak var notesTextField: UITextView!
    @IBOutlet weak var taskNameText: UITextField!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    let appContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var taskItem : Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (super.viewIfLoaded != nil && taskItem != nil){
            notesTextField.text = taskItem?.notes
            taskNameText.text = taskItem?.name
            progressSlider.value = Float((taskItem?.progress.description)!) as! Float
            reminderSwitch.isOn = taskItem!.hasReminder
            progressLabel.text = String(taskItem?.progress.description ?? "0") + "%"
            dueDatePicker.date = taskItem!.dueDate!
        }
    }
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
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
        
        if dueDatePicker.date > Calendar.current.startOfDay(for: (taskItem?.task_to_project?.dueDate!)!) {
            let alert = UIAlertController(title: "Incorrect date",message: "The due date cannot be after the project due date",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
    
        if startDatePicker.date > Calendar.current.startOfDay(for: (taskItem?.task_to_project?.dueDate!)!){
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
        
        taskItem?.dueDate = dueDatePicker.date
        taskItem?.name = taskNameText.text
        
        if taskItem?.hasReminder == true && self.reminderSwitch.isOn == false{
            // remove reminder
            RemoveNotification()
        }
        else if taskItem?.hasReminder == false && self.reminderSwitch.isOn == true{
            // add notification
            AddNotification()
            
        }
        else if taskItem?.hasReminder == true && reminderSwitch.isOn == true{
            // Remove existing notification and add updated one
            RemoveNotification()
            AddNotification()
        }
        
        taskItem?.notes = notesTextField.text
        taskItem?.progress = Int16(progressSlider.value)
        taskItem?.hasReminder = reminderSwitch.isOn
        taskItem?.startDate = startDatePicker.date
        
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        dismiss(animated: true
            , completion: nil)
    }
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
        dismiss(animated: true
            , completion: nil)
    }
    @IBAction func ProgressSlider_OnChange(_ sender: UISlider) {
        let progress = sender.value
        progressLabel.text = String(Int16(progress)) + "% progress"
    }
    
    func RemoveNotification(){
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [(taskItem?.dayReminder!.uuidString)!])
    }
    
    func AddNotification(){
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
            if granted{
                let dayContent = UNMutableNotificationContent()
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                
                dayContent.title = "A task is getting near the deadline"
                let projectName = (self.taskItem?.task_to_project)!.name
                dayContent.body = self.taskItem!.name! + " belonging to the project "
                dayContent.body += projectName! + " has passed the due date: "
                dayContent.body += formatter.string(from: self.taskItem!.dueDate!)
                dayContent.categoryIdentifier = "alarm"
                dayContent.sound = UNNotificationSound.default
                
                let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day), from: self.taskItem!.dueDate!)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let dayId = UUID()
                let dayRequest = UNNotificationRequest(identifier: dayId.uuidString, content: dayContent, trigger: trigger)
                center.add(dayRequest, withCompletionHandler: { error in
                    if let error = error {
                        //handle error
                        let alert = UIAlertController(title: "Error",message: "An error occurred setting up notifications for this task",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self.present(alert, animated: true, completion: nil)
                        return
                    } else {
                        //notification set up successfully
                        self.taskItem!.dayReminder = dayId
                    }
                })
                
                
                
            }
            else{
                return
            }
            
        })
    }
}
