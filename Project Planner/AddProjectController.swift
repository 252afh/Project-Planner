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
    
    @IBOutlet weak var CalendarSwitch: UISwitch!
    @IBOutlet weak var PriorityPicker: UISegmentedControl!
    @IBOutlet weak var NotesTextField: UITextView!
    @IBOutlet weak var DatePicker: UIDatePicker!
    @IBOutlet weak var ProjectName: UITextField!
    var project:Project!
    let appContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.NotesTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.NotesTextField.layer.borderWidth = 1
        ProjectName.becomeFirstResponder()
    }
    
    @IBAction func SaveButton_OnClick(_ sender: UIButton) {
        if (ProjectName.text == "" || ProjectName.text == nil ){
            //Alert
            let alert = UIAlertController(title: "Missing project name",message: "Enter a name for the project",preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        let newProject = Project(context: appContext)
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
                let insertedEvent = insertEvent(store: eventStore, project: newProject)
                if insertedEvent.title != nil{
                    newProject.calenderId = UUID(uuidString: insertedEvent.calendarItemIdentifier)
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
                            let insertedEvent = self!.insertEvent(store: eventStore, project: newProject)
                            if insertedEvent.title != nil{
                                newProject.calenderId = UUID(uuidString: insertedEvent.calendarItemIdentifier)
                            }
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
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        dismiss(animated: true
            , completion: nil)        
    }
    
    func insertEvent(store: EKEventStore, project: Project) -> EKEvent{
        let calendars = store.calendars(for: .event)
        
        for calendar in calendars {
            // 2
            if calendar.title == "Project_Planner" {
                // 3
                //let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate!)
                
                // 4
                let event = EKEvent(eventStore: store)
                event.calendar = calendar
                event.title = project.name
                event.startDate = project.dueDate
                event.endDate = project.dueDate
                event.isAllDay = true
                event.notes = project.notes
                
                // 5
                do {
                    try store.save(event, span: .thisEvent)
                    return event
                }
                catch {
                    let alert = UIAlertController(title: "Error",message: "An error occurred adding a calendar entry", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        return EKEvent()
    }
    
    @IBAction func CancelButton_OnClick(_ sender: UIButton) {
       dismiss(animated: true
        , completion: nil)
    }
}


