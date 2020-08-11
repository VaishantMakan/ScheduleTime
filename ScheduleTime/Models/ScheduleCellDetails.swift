//
//  Data.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 13/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import Foundation
import RealmSwift

class ScheduleCellDetails: Object {
    
    @objc dynamic var title: String = ""
    @objc dynamic var startingTime: String = ""
    @objc dynamic var endingTime: String = ""
    @objc dynamic var describe: String = ""
    
    //checkMark
    @objc dynamic var done: Bool = false
    
    //notification
    @objc dynamic var notificationState: Bool = false
    
    //for sorting
    @objc dynamic var sortingTime: Date?
    
    //for dateComponents
    @objc dynamic var dateComponentHour: Int = 0
    @objc dynamic var dateComponentMinute: Int = 0
    @objc dynamic var isLeapMonth: Bool = false
}
