//
//  ScheduleTableViewCell.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 09/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

//to save the state of the current cell 
protocol CheckMarkSaveDelegate: AnyObject {
    func checkMarkSaveCell(_ checkMarkSaveCell: ScheduleTableViewCell, indexNumber: Int)
}

// to save the current state of notifications
protocol NotificationDelegate: AnyObject {
    func notificationStateCell(_ notificationStateCell: ScheduleTableViewCell, indexNumber: Int)
}

//UITableViewCell
class ScheduleTableViewCell: SwipeTableViewCell {
    
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var activityView: UIView!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var activityBodyLabel: UILabel!
    
    @IBOutlet weak var checkMarkButton: UIButton!
    @IBOutlet weak var notificationButton: UIButton!
    
    @IBOutlet weak var timeImageView: UIImageView!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var titleImageView: UIImageView!
    
    let realm = try! Realm()
    
    //the delegate, remember to set it as weak to prevent cycles
    weak var delegateCheckMark : CheckMarkSaveDelegate?
    weak var delegateNotification : NotificationDelegate?
    
    //for delegate method
    var indexNumber: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // view did load of this xib
        
        timeView.layer.cornerRadius = timeView.frame.size.height / 5
        
        activityView.layer.cornerRadius = activityView.frame.size.height / 5
        
        timeImageView.layer.cornerRadius = timeImageView.frame.size.height / 5
        
        descriptionView.layer.cornerRadius = descriptionView.frame.size.height / 5
        
        titleImageView.layer.cornerRadius = titleImageView.frame.size.height / 5
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func checkButtonPressed(_ sender: UIButton) {
        
        if let _ = delegateCheckMark,
            let indexNumber = indexNumber {
            self.delegateCheckMark?.checkMarkSaveCell(self,indexNumber: indexNumber )
        }
    }
    
    @IBAction func notificationButtonPressed(_ sender: UIButton) {
        
        if let _ = delegateNotification,
            let indexNumber = indexNumber {
            self.delegateNotification?.notificationStateCell(self, indexNumber: indexNumber )
        }
    }
    
}
