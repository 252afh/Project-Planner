//
//  EditProjectController.swift
//  Project Planner
//
//  Created by user153807 on 5/3/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit
import EventKit

class EditProjectController : UIViewController {
    
    @IBOutlet weak var projectName: UITextField!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    @IBOutlet weak var noteText: UITextView!
    @IBOutlet weak var dueDate: UIDatePicker!
    var delegate: ProjectDetailController!
    
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
            reminderSwitch.isOn = projectItem!.calendarEntry
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
        
        if dueDate.date < Date.init(){
            let alert = UIAlertController(title: "Incorrect due date",message: "The due date has to be in the future",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        projectItem?.notes = noteText.text
        projectItem?.name = projectName.text
        projectItem?.priority = Int16(prioritySelector.selectedSegmentIndex)
        
        if projectItem?.calendarEntry == false && reminderSwitch.isOn == true{
            projectItem?.dueDate = dueDate.date
            AddReminder()
        }
        else if projectItem?.calendarEntry == true && reminderSwitch.isOn == false{
            DeleteReminder()
            projectItem?.dueDate = dueDate.date
        }
        else if projectItem?.calendarEntry == true && reminderSwitch.isOn == true {
            DeleteReminder()
            projectItem?.dueDate = dueDate.date
            AddReminder()
        }
        
        projectItem?.calendarEntry = reminderSwitch.isOn
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        delegate.UpdateProjectItem(newProject: projectItem!)
        
        dismiss(animated: true
            , completion: nil)
    }
    
    func AddReminder(){
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            insertEvent(store: eventStore, project: projectItem!)
        case .denied:
            let alert = UIAlertController(title: "Error",message: "Permission denied to add calendar entry",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion:
                {[weak self] (granted: Bool, error: Error?) -> Void in
                    if granted {
                        self!.insertEvent(store: eventStore, project: self!.projectItem!)
                    } else {
                        let alert = UIAlertController(title: "Error",message: "Permission denied to add calendar entry",preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(OKAction)
                        self?.present(alert, animated: true, completion: nil)
                        return
                    }
            })
        default:
            let alert = UIAlertController(title: "Error",message: "An error occurred adding a calendar entry",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
    
    func DeleteReminder(){
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        for calendar in calendars{
            if calendar.title == "Project_Planner"{
                let pastPredicate = eventStore.predicateForEvents(withStart: projectItem!.dueDate!, end: projectItem!.dueDate!, calendars: [calendar])
                
                let events = eventStore.events(matching: pastPredicate)
                for foundReminders in events{
                    if foundReminders.calendarItemIdentifier == projectItem?.calenderId?.uuidString{
                        let remindersToDelete = true
                        let span = EKSpan(rawValue: 0)
                        do {
                            try eventStore.remove(foundReminders, span: span!, commit: false)
                        }
                        catch {
                            
                        }
                        if remindersToDelete {
                            do {
                                try eventStore.commit()
                            }
                            catch {
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    func insertEvent(store: EKEventStore, project: Project){
        let calendars = store.calendars(for: .event)
        
        for calendar in calendars {
            if calendar.title == "Project_Planner" {
                let event = EKEvent(eventStore: store)
                event.calendar = calendar
                
                event.title = project.name
                event.startDate = project.dueDate
                event.endDate = project.dueDate
                event.isAllDay = true
                event.notes = project.notes
                
                do {
                    try store.save(event, span: .thisEvent)
                }
                catch {
                    let alert = UIAlertController(title: "Error",message: "An error occurred adding a calendar entry", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            }
        }
    }
}
