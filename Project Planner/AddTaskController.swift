//
//  AddTaskController.swift
//  Project Planner
//
//  Created by user153807 on 4/28/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class AddTaskController : UIViewController{
    
    // Task progress slider
    @IBOutlet weak var ProgressSlider: UISlider!
    
    // Task name
    @IBOutlet weak var TaskNameText: UITextField!
    
    // Task progress slider value displayed
    @IBOutlet weak var progressLabel: UILabel!
    
    // Task start date
    @IBOutlet weak var startdatePicker: UIDatePicker!
    
    // Task note
    @IBOutlet weak var NoteText: UITextView!
    
    // Task due date
    @IBOutlet weak var DatePicker: UIDatePicker!
    
    // Task reminder switch
    @IBOutlet weak var ReminderSwitch: UISwitch!
    
    // The detail controller to reload tasks when added
    var delegate:DetailViewController?
    
    // The application context to save the added task
    let appContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Sets up the fields when loading the form
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.NoteText.layer.borderColor = UIColor.lightGray.cgColor
        self.NoteText.layer.borderWidth = 1
        
        self.view.layer.borderColor = UIColor.white.cgColor
        self.view.layer.borderWidth = 3
        
        self.startdatePicker.backgroundColor = UIColor.gray
        self.DatePicker.backgroundColor = UIColor.gray
    }
    
    // Saves the added task and sets up notification
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
        if let projectItem = projectItem, let dueDate = projectItem.dueDate{
            if Calendar.current.startOfDay(for: DatePicker.date) < Calendar.current.startOfDay(for: Date.init()){
                let alert = UIAlertController(title: "Invalid date",message: "Due date cannot be earlier than today",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if Calendar.current.startOfDay(for: startdatePicker.date) < Calendar.current.startOfDay(for: Date.init()){
                let alert = UIAlertController(title: "Invalid date",message: "Start date cannot be earlier than today",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if Calendar.current.startOfDay(for: startdatePicker.date) > Calendar.current.startOfDay(for: DatePicker.date){
                let alert = UIAlertController(title: "Invalid date",message: "Start date cannot be after the task due date",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if Calendar.current.startOfDay(for: startdatePicker.date) > Calendar.current.startOfDay(for: dueDate){
                let alert = UIAlertController(title: "Invalid date",message: "Start date cannot be after the project due date",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if Calendar.current.startOfDay(for: DatePicker.date) > Calendar.current.startOfDay(for: dueDate){
                let alert = UIAlertController(title: "Invalid date",message: "Due date cannot be after the project due date",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if TaskNameText.text == "" || TaskNameText.text == nil{
                let alert = UIAlertController(title: "Task name missing",message: "A task name is required to create a task",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let task = Task(context: appContext)
            
            task.dueDate = DatePicker.date
            task.hasReminder = ReminderSwitch.isOn
            task.name = TaskNameText.text
            task.notes = NoteText.text
            task.progress = Int16(ProgressSlider.value)
            task.startDate = startdatePicker.date
            
            task.task_to_project = projectItem
            
            let center = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
                if granted{
                    let dayContent = UNMutableNotificationContent()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    
                    dayContent.title = "A task is getting near the deadline"
                    let projectName = self.projectItem?.name
                    if let name = task.name{
                        dayContent.body = name + " belonging to the project "
                    }
                    
                    if let projectName = projectName{
                        dayContent.body += projectName + " has passed the due date: "
                    }
                    
                    if let dueDate = task.dueDate{
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
                                let alert = UIAlertController(title: "Error",message: error.localizedDescription,preferredStyle: .alert)
                                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(OKAction)
                                self.present(alert, animated: true, completion: nil)
                                return
                            } else {
                                //notification set up successfully
                                task.dayReminder = dayId
                                self.SaveTask(task: task)
                            }
                        })
                    }
                }
                else{
                    return
                }
            })
        }
    }
    
    // Saves the task using the main thread
    func SaveTask(task:Task!){
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            self.delegate?.tasks?.append(task)
            self.delegate?.ReloadTasks()
            self.delegate?.RefreshProjectProgress()
            
            self.dismiss(animated: true
                , completion: nil)
        }
    }
    
    // Cancels adding a task and closes the popup
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
        self.dismiss(animated: true
            , completion: nil)
    }
    
    // Changes the progress label value when the progress slider value is changed
    @IBAction func ProgressSlider_OnChange(_ sender: UISlider) {
        let progress = sender.value
        progressLabel.text = String(Int16(progress)) + "% progress"
    }
    var projectItem : Project?
}
