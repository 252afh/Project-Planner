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
    
    // The name of the project
    @IBOutlet weak var projectName: UITextField!
    
    // The priority of the project
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    
    // The note text to add to the project
    @IBOutlet weak var noteText: UITextView!
    
    // The due date of the project
    @IBOutlet weak var dueDate: UIDatePicker!
    
    // The controller that opens this popup
    var delegate: ProjectDetailController!
    
    // Whether a calendar reminder should be set
    @IBOutlet weak var reminderSwitch: UISwitch!
    
    // The project item to edit
    var projectItem : Project?
    
    // Handles displaying the project to edit in the popup on load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.noteText.layer.borderColor = UIColor.lightGray.cgColor
        self.noteText.layer.borderWidth = 1
        projectName.becomeFirstResponder()
        
        if self.isViewLoaded == true{
            if let projectItem = projectItem{
                projectName.text = projectItem.name
                
                if let priority = Int(projectItem.priority.description){
                    prioritySelector.selectedSegmentIndex = priority
                }
                
                if let due = projectItem.dueDate{
                    dueDate.date = due
                }
                
                noteText.text = projectItem.notes
                reminderSwitch.isOn = projectItem.calendarEntry
            }
            
            dueDate.backgroundColor = UIColor.gray
            self.view.layer.borderColor = UIColor.white.cgColor
            self.view.layer.borderWidth = 3
        }
    }
    
    // Cancels the editing of the current project
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
        dismiss(animated: true
            , completion: nil)
    }
    
    // Edits a project when the save button is clicked
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
        if projectName.text == nil || projectName.text == "" {
            let alert = UIAlertController(title: "Project name missing",message: "A project name is required to update a project",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if Calendar.current.startOfDay(for: dueDate.date) < Calendar.current.startOfDay(for: Date.init()){
            let alert = UIAlertController(title: "Incorrect due date",message: "The due date has to be in the future",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if let projectItem = projectItem{
            projectItem.notes = noteText.text
            projectItem.name = projectName.text
            projectItem.priority = Int16(prioritySelector.selectedSegmentIndex)
            
            if projectItem.calendarEntry == false && reminderSwitch.isOn == true{
                projectItem.dueDate = dueDate.date
                AddReminder()
            }
            else if projectItem.calendarEntry == true && reminderSwitch.isOn == false{
                DeleteReminder()
                projectItem.dueDate = dueDate.date
            }
            else if projectItem.calendarEntry == true && reminderSwitch.isOn == true {
                DeleteReminder()
                projectItem.dueDate = dueDate.date
                AddReminder()
            }
            
            projectItem.calendarEntry = reminderSwitch.isOn
            
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            delegate.UpdateProjectItem(newProject: projectItem)
            
            dismiss(animated: true
                , completion: nil)
        }
    }
    
    // Adds a reminder for the current project
    func AddReminder(){
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            if let projectItem = projectItem{
                insertEvent(store: eventStore, project: projectItem)
            }
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
                        if let self = self, let projectItem = self.projectItem{
                            self.insertEvent(store: eventStore, project: projectItem)
                        }
                    } else {
                        if let self = self{
                            let alert = UIAlertController(title: "Error",message: "Permission denied to add calendar entry",preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(OKAction)
                            self.present(alert, animated: true, completion: nil)
                        }
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
    
    // Deletes an event for the current project
    func DeleteReminder(){
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        for calendar in calendars{
            if calendar.title == "Project_Planner"{
                if let projectItem = projectItem, let dueDate = projectItem.dueDate, let calendarId = projectItem.calenderId{
                    let pastPredicate = eventStore.predicateForEvents(withStart: dueDate, end: dueDate, calendars: [calendar])
                    
                    let events = eventStore.events(matching: pastPredicate)
                    for foundReminders in events{
                        if foundReminders.calendarItemIdentifier == calendarId.uuidString{
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
    }
    
    // Inserts an event for the given project into the event store
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
