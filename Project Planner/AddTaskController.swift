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
    @IBOutlet weak var ProgressSlider: UISlider!
    @IBOutlet weak var TaskNameText: UITextField!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var startdatePicker: UIDatePicker!
    @IBOutlet weak var NoteText: UITextView!
    @IBOutlet weak var DatePicker: UIDatePicker!
    @IBOutlet weak var ReminderSwitch: UISwitch!
    var delegate:DetailViewController?
    let appContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.NoteText.layer.borderColor = UIColor.lightGray.cgColor
        self.NoteText.layer.borderWidth = 1
        self.view.layer.borderColor = UIColor.white.cgColor
        self.view.layer.borderWidth = 3
        self.startdatePicker.backgroundColor = UIColor.gray
        self.DatePicker.backgroundColor = UIColor.gray
    }
    
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
        
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
        
        if startdatePicker.date > Calendar.current.startOfDay(for: projectItem!.dueDate!){
            let alert = UIAlertController(title: "Invalid date",message: "Start date cannot be after the project due date",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if DatePicker.date > Calendar.current.startOfDay(for: projectItem!.dueDate!){
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
                dayContent.body = task.name! + " belonging to the project "
                dayContent.body += projectName! + " has passed the due date: "
                dayContent.body += formatter.string(from: task.dueDate!)
                dayContent.categoryIdentifier = "alarm"
                dayContent.sound = UNNotificationSound.default
                
                let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day), from: task.dueDate!)
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
                        task.dayReminder = dayId
                        self.SaveTask(task: task)
                    }
                })
                
                
                
            }
            else{
                return
            }
            
        })
        
        
    }
    
    func SaveTask(task:Task!){
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            self.dismiss(animated: true
                , completion: nil)
            self.delegate?.tasks?.append(task)
            print(task.dayReminder?.uuidString)
            self.delegate?.ReloadTasks()
            self.delegate?.RefreshProjectProgress()
        }
    }
    
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
        self.dismiss(animated: true
            , completion: nil)
    }
    
    @IBAction func ProgressSlider_OnChange(_ sender: UISlider) {
        let progress = sender.value
        progressLabel.text = String(Int16(progress)) + "% progress"
    }
    var projectItem : Project?
}
