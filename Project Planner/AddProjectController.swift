//
//  AddProjectController.swift
//  Project Planner
//
//  Created by user153807 on 4/27/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit
import EventKit

class AddProjectController: UIViewController {
    // Whether to create a calendar event
    @IBOutlet weak var CalendarSwitch: UISwitch!
    
    // Project priority
    @IBOutlet weak var PriorityPicker: UISegmentedControl!
    
    // Project notes
    @IBOutlet weak var NotesTextField: UITextView!
    
    // Project due date
    @IBOutlet weak var DatePicker: UIDatePicker!
    
    // Project name
    @IBOutlet weak var ProjectName: UITextField!
    
    // Project to create
    var newProject:Project!
    
    // Master detail form
    var delegate:MasterViewController!
    
    // The application context used to save the new project
    let appContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Sets up fields
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.NotesTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.NotesTextField.layer.borderWidth = 1
        
        self.DatePicker.backgroundColor = UIColor.gray
        
        self.view.layer.borderColor = UIColor.white.cgColor
        self.view.layer.borderWidth = 3
        
        ProjectName.becomeFirstResponder()
    }
    
    // Saves the new project and adds an event
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {        
        if (ProjectName.text == "" || ProjectName.text == nil ){
            let alert = UIAlertController(title: "Missing project name",message: "Enter a name for the project",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if Calendar.current.startOfDay(for: DatePicker.date) < Calendar.current.startOfDay(for: Date.init()){
            let alert = UIAlertController(title: "Invalid date",message: "Start date cannot be earlier than today",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        newProject = Project(context: appContext)
        
        newProject.createdDate = Date.init()
        newProject.dueDate = DatePicker.date
        newProject.name = ProjectName.text
        newProject.notes = NotesTextField.text
        newProject.priority = Int16(PriorityPicker.selectedSegmentIndex)
        newProject.calendarEntry = CalendarSwitch.isOn
        
        if (CalendarSwitch.isOn){
            let eventStore = EKEventStore()
        
            switch EKEventStore.authorizationStatus(for: .event) {
            case .authorized:
                insertEvent(store: eventStore, project: newProject)
            case .denied:
                let alert = UIAlertController(title: "Error",message: "Permission denied to add calendar entry",preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
                return
            case .notDetermined:
                eventStore.requestAccess(to: .event, completion:
                    {(granted: Bool, error: Error?) -> Void in
                        if granted {
                            self.insertEvent(store: eventStore, project: self.newProject)
                        } else {
                            let alert = UIAlertController(title: "Error",message: "Permission denied to add calendar entry",preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(OKAction)
                            self.present(alert, animated: true, completion: nil)
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
        
        delegate.selectTableIndex(index: IndexPath(row: 0, section: 0))
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // Inserts an event for the new project into the calendar
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
                    newProject.calenderId = UUID(uuidString: event.calendarItemIdentifier)
                }
                catch {
                    let alert = UIAlertController(title: "Error",message: "An error occurred adding a calendar entry", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // Cancels creating a new project and closes the popup
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
       dismiss(animated: true
        , completion: nil)
    }
}


