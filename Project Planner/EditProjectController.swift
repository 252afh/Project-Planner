//
//  EditProjectController.swift
//  Project Planner
//
//  Created by user153807 on 5/3/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit

class EditProjectController : UIViewController {
    
    @IBOutlet weak var projectName: UITextField!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    @IBOutlet weak var noteText: UITextView!
    @IBOutlet weak var dueDate: UIDatePicker!
    
    @IBOutlet weak var reminderSwitch: UISwitch!
    var projectItem : Project?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.noteText.layer.borderColor = UIColor.lightGray.cgColor
        self.noteText.layer.borderWidth = 1
        projectName.becomeFirstResponder()
        
        if self.isViewLoaded == true && self.projectItem != nil{
            projectName.text = projectItem?.name
            prioritySelector.selectedSegmentIndex = Int((projectItem?.priority.description)!)!
            dueDate.date = projectItem!.dueDate!
            noteText.text = projectItem?.notes
        }
    }
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
        dismiss(animated: true
            , completion: nil)
    }
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
        if projectName.text == nil || projectName.text == "" {
            let alert = UIAlertController(title: "Project name missing",message: "A project name is required to update a project",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if dueDate.date <= Date.init(){
            let alert = UIAlertController(title: "Incorrect due date",message: "The due date has to be in the future",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        projectItem?.notes = noteText.text
        projectItem?.name = projectName.text
        projectItem?.priority = Int16(prioritySelector.selectedSegmentIndex)
        projectItem?.calendarEntry = reminderSwitch.isOn
        projectItem?.dueDate = dueDate.date
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        dismiss(animated: true
            , completion: nil)
    }
}
