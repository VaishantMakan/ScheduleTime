//
//  NewActivityTableViewController.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 09/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

protocol AddScheduleDelegate {
    func addSchedule(cell: ScheduleCellDetails, component: DateComponents, set: Set<String>)
}

class NewActivityTableViewController: UITableViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var startingTimeTxt: UITextField!
    
    @IBOutlet weak var endingTimeTxt: UITextField!
    
    @IBOutlet weak var titleErrorLabel: UILabel!
    
    @IBOutlet weak var timeErrorLabel: UILabel!
    
    var delegate: AddScheduleDelegate?
    
    let datePickerTime = UIDatePicker()
    
    // the textfield that is currently being edited...
    var currentTextFieldName: UITextField?
    
    //creating Realm 
    let realm = try! Realm()
    
    //notification
    var notificationComponent: DateComponents!
    
    //set to check if the same starting Time used before or not
    var startTimeSet: Set<String> = Set<String>()
    
    //MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // layout design
        titleTextField.layer.cornerRadius = titleTextField.frame.size.height / 5
        
        descriptionTextView.layer.cornerRadius = descriptionTextView.frame.size.height / 10
        
        //delegates for textfields....
        startingTimeTxt.delegate = self
        endingTimeTxt.delegate = self
        titleTextField.delegate = self
        
        //date picker mode
        datePickerTime.datePickerMode = .time
        if #available(iOS 13.4, *) {
            datePickerTime.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        
        //to dismiss the keyboard on tapping anywhere else
        hideKeyboardOnTap()
        
        //MARK: - To add a done button to TextView Keyboard (for description TextView)
        let toolbar = UIToolbar()
        toolbar.sizeToFit() //will fit to full screen
        
        //bar done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDescripton(sender:)))
        
        toolbar.setItems([doneButton], animated: true)
        
        //assign toolbar
        descriptionTextView.inputAccessoryView = toolbar
    }
    
    //done button function for description TextView
    @objc func doneDescripton(sender: UIBarButtonItem){
        descriptionTextView.resignFirstResponder()
    }
    //MARK: - Date Picker as Time Functions
    func createDatePicker(textField: UITextField) {
        
        currentTextFieldName = textField
        
        //toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit() //will fit to full screen
        
        //Tool bar done button
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed(sender: )))
        //remember in selector u dont want to call the method , just name it
        toolbar.setItems([doneBtn], animated: true)
        
        //assign toolbar
        textField.inputAccessoryView = toolbar
        
        //assign date picker to textfield
        textField.inputView = datePickerTime
        
        //as u edit the date , the textfield also gets changed automatically
        datePickerTime.addTarget(self, action: #selector(timeChanged(datePicker: )), for: .valueChanged)
    }
    
    @objc func timeChanged(datePicker: UIDatePicker) {
        
        //formatter
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        currentTextFieldName?.text = formatter.string(from: datePickerTime.date)
        
        if currentTextFieldName == startingTimeTxt {
            //notification
            notificationComponent = datePickerTime.calendar.dateComponents([.hour, .minute], from: datePickerTime.date)
        }
    }
    
    //for the done button of textfield tool bar keyboard
    @objc func donePressed(sender: UIBarButtonItem) {
        
        //formatter
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        currentTextFieldName?.text = formatter.string(from: datePickerTime.date)
        
        if currentTextFieldName == startingTimeTxt {
            //notification
            notificationComponent = datePickerTime.calendar.dateComponents([.hour, .minute], from: datePickerTime.date)
        }
        
        self.view.endEditing(true)
    }
    
    //MARK: - To dismiss the keyboard on tap outside text field
    
    internal func hideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(gestureRecognizer: )))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    @objc private func hideKeyboard(gestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    //MARK: - Seagues
    @IBAction func AddButtonPressed(_ sender: UIBarButtonItem) {
        
        print(startTimeSet)
        //to check if necessary items filled or not...
        var check: Bool = true
        
        let cell = ScheduleCellDetails()
        
        if titleTextField.text == "" {
            check = false
            titleErrorLabel.text = "Please add a title"
        } else {
            cell.title = titleTextField.text!
            titleErrorLabel.text = ""
        }
        
        if startingTimeTxt.text == "" {
            check = false
            timeErrorLabel.text = "Please add a starting time"
        } else {
            
            if startTimeSet.contains(startingTimeTxt.text!) {
                check = false
                timeErrorLabel.text = "This starting Time is already in use. Please add a different time"
            } else {
                cell.startingTime = startingTimeTxt.text!
                startTimeSet.insert(startingTimeTxt.text!)
                
                if check == true {
                    timeErrorLabel.text = ""
                }
            }
        }
        
        if endingTimeTxt.text == "" {
            check = false
            timeErrorLabel.text = "Please add an ending time"
        } else {
            cell.endingTime = endingTimeTxt.text!
            
            if check == true {
                timeErrorLabel.text = ""
            }
        }
        
        cell.describe = descriptionTextView.text ?? ""
        
        if check == true {
            
            cell.sortingTime = getSortingTime(from: cell.startingTime)
            cell.dateComponentHour = notificationComponent.hour!
            cell.dateComponentMinute = notificationComponent.minute!
            cell.isLeapMonth = notificationComponent.isLeapMonth!
        
            saveSchedule(cell: cell)
        
            delegate?.addSchedule(cell: cell, component: notificationComponent, set: startTimeSet)
            dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func CancelButtonPressed(_ sender: UIBarButtonItem) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func getSortingTime(from timeString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        
        let date = dateFormatter.date(from: timeString)!
        return date
    }
    
    //MARK: - Realm saving and loading methods
    func saveSchedule(cell: ScheduleCellDetails) {
        do {
            try realm.write {
                realm.add(cell)
            }
        } catch {
            print("Error saving category \(error)")
        }
    }
}

//MARK: - TextField Delegate
extension NewActivityTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == startingTimeTxt {
            createDatePicker(textField: textField)
        }
        else if textField == endingTimeTxt {
            createDatePicker(textField: textField)
        }
    }
    
    //for the return button in title text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

// MARK: - Table view data source

//IT WAS IMPORTANT TO COMMENT THE NEXT TWO METHODS BCUZ WE HAVE STATIC CELLS OTHERWISE THEY WOULDNT HAVE SHOWN UP !

/*
 override func numberOfSections(in tableView: UITableView) -> Int {
 // #warning Incomplete implementation, return the number of sections
 return 0
 }
 
 override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 // #warning Incomplete implementation, return the number of rows
 return 0
 }
 */
/*
 override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
 
 // Configure the cell...
 
 return cell
 }
 */

/*
 // Override to support conditional editing of the table view.
 override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
 // Return false if you do not want the specified item to be editable.
 return true
 }
 */

/*
 // Override to support editing the table view.
 override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
 if editingStyle == .delete {
 // Delete the row from the data source
 tableView.deleteRows(at: [indexPath], with: .fade)
 } else if editingStyle == .insert {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
 
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
 // Return false if you do not want the item to be re-orderable.
 return true
 }
 */

/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */


