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
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var progressCircle: CircularProgressBar!
    @IBOutlet weak var dueDateLabel: UILabel!
    var task: Task?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
