//
//  CustomTableCell.swift
//  Project Planner
//
//  Created by user153807 on 4/29/19.
//  Copyright © 2019 w1442006. All rights reserved.
//

import Foundation
import UIKit

class CustomTableCell : UITableViewCell {
    // Task name
    @IBOutlet weak var nameLabel: UILabel!
    
    // Task progress
    @IBOutlet weak var progressCircle: CircularProgressBar!
    
    // Task due date
    @IBOutlet weak var dueDateLabel: UILabel!
    
    // Task notes
    @IBOutlet weak var noteText: UITextView!
    
    // Task start date
    @IBOutlet weak var startDateLabel: UILabel!
    
    // The cell task
    var task: Task?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
