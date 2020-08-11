//
//  FirstViewController.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 09/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class FirstViewController: UIViewController {
    
    @IBOutlet weak var scheduleTableView: UITableView!
    
    @IBOutlet weak var dateDayLabel: UILabel!
    
    let realm = try! Realm()
    
    var scheduleCell: Results<ScheduleCellDetails>?
    
    //for editing an existing cell
    var cellToBeSentToEdit: ScheduleCellDetails?
    
    //notification
    let notifications = Notifications()
    var notificationDateComponents = [String: DateComponents]()
    
    //starting time SET
    var startingTimeSet: Set = Set<String>() //declared an empty set
    
    //MARK: - View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scheduleTableView.dataSource = self
        scheduleTableView.delegate = self
        
        //registering the new design file
        scheduleTableView.register(UINib(nibName:K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        //for the date and day that is displayed at the top
        dateDayLabel.text = getDateDay()
        
        //reading from realm
        loadSchedule()
    }
    
    func loadSchedule() {
        //sorted the cells according to the time that the user puts in...
        scheduleCell = realm.objects(ScheduleCellDetails.self).sorted(byKeyPath: "sortingTime")
        
        scheduleTableView.reloadData()
    }
    //MARK: - Get Day and Date
    func getDateDay() -> String {
        
        var dateDay:String
        
        //for month
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        let nameOfMonth = dateFormatter.string(from: now)
        
        //for date ...check the extension of date below first !
        let date = Date.getCurrentDate()
        
        //for day
        let today = Date()
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "EEEE"
        let dayInWeek = dateFormatter2.string(from: today)
        
        dateDay = "\(dayInWeek), \(date) \(nameOfMonth)"
        
        return dateDay
    }
    
    //MARK: - Buttons and Segues
    @IBAction func clearAllButton(_ sender: UIBarButtonItem) {
        
        //remove all notifications....
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications() // To remove all delivered                                                                         notifications
        center.removeAllPendingNotificationRequests()
        
        //
        try! realm.write {
            realm.deleteAll()
        }
        startingTimeSet.removeAll()
        
        scheduleTableView.reloadData()
    }
    
    @IBAction func addNewActivityButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addItemSegue", sender: self)
    }
    
    //this func is called everytime a segue is performed
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addItemSegue" {
            let vc = segue.destination as! NewActivityTableViewController
            vc.delegate = self
            vc.startTimeSet = startingTimeSet
            
        } else if segue.identifier == "editItemSegue" {
            let vc = segue.destination as! EditCellTableViewController
            vc.delegate = self
            vc.cellToEdit = cellToBeSentToEdit
            
            print(cellToBeSentToEdit!.startingTime)
            
            vc.prevDateComponent = notificationDateComponents[cellToBeSentToEdit!.startingTime]
            vc.startTimeSet = startingTimeSet
        }
    }
}
//MARK: - TableView DataSource
//this means whenever our tableView loads up , its going to make a request for data
extension FirstViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleCell?.count ?? 1
    }
    
    //called for as many times as there are numberOfRows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = scheduleTableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! ScheduleTableViewCell
        
        let startTime = scheduleCell?[indexPath.row].startingTime ?? ""
        let endTime = scheduleCell?[indexPath.row].endingTime ?? ""
        
        if notificationDateComponents[startTime] == nil {
            print("It is eureka time")
            
            let date = Date()
            let calendar = Calendar.current
            
            var dateComponent = calendar.dateComponents([.hour, .minute], from: date)
            dateComponent.hour = scheduleCell?[indexPath.row].dateComponentHour
            dateComponent.minute = scheduleCell?[indexPath.row].dateComponentMinute
            dateComponent.isLeapMonth = scheduleCell?[indexPath.row].isLeapMonth
            
            notificationDateComponents[startTime] = dateComponent
        }
        
        cell.timeLabel.text = startTime + " - " + endTime
        
        cell.activityBodyLabel.text = scheduleCell?[indexPath.row].title ?? "Press '+' button to add new Schedule"
        
        cell.descriptionLabel.text = scheduleCell?[indexPath.row].describe ?? " No description added...."
        
        cell.indexNumber = indexPath.row
        
        cell.delegateCheckMark = self
        cell.delegateNotification = self
        cell.delegate = self
        
        //change notification image and state ....
        let whiteAlertImage = UIImage(named: "alertWhite")
        let purpleAlertImage = UIImage(named: "alertPurple")
        
        if scheduleCell?[indexPath.row].notificationState == false {
            cell.notificationButton.setImage(whiteAlertImage, for: .normal)
            
            if let component = notificationDateComponents[startTime] {
                self.notifications.cancelNotification(from: component , cell: cell)
            }
            
        }else {
            cell.notificationButton.setImage(purpleAlertImage, for: .normal)
            
            if let component = notificationDateComponents[startTime] {
                self.notifications.scheduleNotification(from: component , cell: cell)
            }
        }
        
        //change checkMark Image accordingly & alter notificationState
        let whiteImage = UIImage(named: "tickWhite")
        let purpleImage = UIImage(named: "tickPurple")
        
        if scheduleCell?[indexPath.row].done == false {
            cell.checkMarkButton.setImage(whiteImage, for: .normal)
            cell.contentView.alpha = 1.0
        }else {
            cell.checkMarkButton.setImage(purpleImage, for: .normal)
            cell.contentView.alpha = 0.3
            
            if scheduleCell?[indexPath.row].notificationState == true {
                notificationStateCell(cell, indexNumber: indexPath.row)
            }
        }
        
        //to enter each cell's starting time in our SET for checking
        startingTimeSet.insert((scheduleCell?[indexPath.row].startingTime)!)
        
        return cell
    }
    
}
//MARK: - extension for date
extension Date {
    
    static func getCurrentDate() -> String {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "dd"
        
        return dateFormatter.string(from: Date())
        
    }
}
//MARK: - TableView Delegate
//whenever the tableView is interacted with this method gets triggered (like selecting a row of the tableView)
extension FirstViewController: UITableViewDelegate {
    
}

//MARK: - CheckMark Delegate to save State
extension FirstViewController: CheckMarkSaveDelegate {
    func checkMarkSaveCell(_ checkMarkSaveCell: ScheduleTableViewCell, indexNumber: Int) {
        
        if let schedule = scheduleCell?[indexNumber] {
            do {
                try realm.write {
                    schedule.done = !schedule.done
                }
            } catch {
                print("Error saving done status, \(error)")
            }
        }
        scheduleTableView.reloadData()
    }
}

//MARK: - Notification Delegate to save notification State
extension FirstViewController: NotificationDelegate {
    func notificationStateCell(_ notificationStateCell: ScheduleTableViewCell, indexNumber: Int) {
        
        if let schedule = scheduleCell?[indexNumber] {
            do {
                try realm.write {
                    schedule.notificationState = !schedule.notificationState
                }
            } catch {
                print("Error saving notification state, \(error)")
            }
        }
        scheduleTableView.reloadData()
    }
}

//MARK: - Swipe Cell Kit Delegate
extension FirstViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        guard orientation == .left else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
            
            if let scheduleCellForDeletion = self.scheduleCell?[indexPath.row] {
                
                self.startingTimeSet.remove(scheduleCellForDeletion.startingTime)
                
                let startTime = scheduleCellForDeletion.startingTime
                
                if let component = self.notificationDateComponents[startTime] {
                    self.notifications.cancelIfEdited(from: component, prevStartingTime: scheduleCellForDeletion.startingTime, prevEndingTime: scheduleCellForDeletion.endingTime)
                }
                
                do {
                    try self.realm.write {
                        self.realm.delete(scheduleCellForDeletion)
                    }
                } catch {
                    print("Error deleting cell, \(error)")
                }
                
                //when using expansionStyle = .destructive below fn editAction... you can't reload the tableview here bcuz it tries to delete the last cell , so comment it
                self.scheduleTableView.reloadData()
            }
            
        }
        
        let editAction = SwipeAction(style: .default, title: "Edit") { (action, indexPath) in
            
            if let scheduleCellToEdit = self.scheduleCell?[indexPath.row] {
                
                self.cellToBeSentToEdit = scheduleCellToEdit
                
                self.performSegue(withIdentifier: "editItemSegue", sender: self)
            }
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "deleteIcon")
        editAction.image = UIImage(named: "IconEdit")
        
        return [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        //options.expansionStyle = .destructive //to swipe and delete ...
        options.transitionStyle = .border
        
        return options
    }
}

//MARK: - Delegate For NewActivityController Add button
extension FirstViewController: AddScheduleDelegate {
    
    func addSchedule(cell: ScheduleCellDetails, component: DateComponents, set: Set<String>) {
        
        notificationDateComponents[cell.startingTime] = component
        startingTimeSet = set
        self.scheduleTableView.reloadData()
    }
}

//MARK: - Delegate For EditCellTableView Controller Edit button
extension FirstViewController: EditScheduleDelegate {
    
    func editSchedule(cell: ScheduleCellDetails, component: DateComponents, previousStartingTime: String, previousEndingTime: String, set: Set<String>) {
        
        if previousStartingTime != cell.startingTime {
            
            if let comp = notificationDateComponents[previousStartingTime] {
                self.notifications.cancelIfEdited(from: comp, prevStartingTime: previousStartingTime, prevEndingTime: previousEndingTime)
            }
            
            notificationDateComponents.removeValue(forKey: previousStartingTime)
            notificationDateComponents[cell.startingTime] = component
            
            startingTimeSet.remove(previousStartingTime)
            startingTimeSet.insert(cell.startingTime)
        }
        
        self.scheduleTableView.reloadData()
    }
}
