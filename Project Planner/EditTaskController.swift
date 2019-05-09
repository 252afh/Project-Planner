//
//  EditTaskController.swift
//  Project Planner
//
//  Created by user153807 on 4/30/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit

class EditTaskController : UIViewController{
    
    @IBOutlet weak var notesTextField: UITextView!
    @IBOutlet weak var taskNameText: UITextField!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var progressLabel: UILabel!
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
        
        if dueDatePicker.date <= Date.init(){
            let alert = UIAlertController(title: "Incorrect due date",message: "The due date has to be in the future",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        taskItem?.notes = notesTextField.text
        taskItem?.name = taskNameText.text
        taskItem?.progress = Int16(progressSlider.value)
        taskItem?.hasReminder = reminderSwitch.isOn
        taskItem?.dueDate = dueDatePicker.date
        
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
}
