//
//  EditCellTableViewController.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 18/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

protocol EditScheduleDelegate {
    func editSchedule(cell: ScheduleCellDetails, component: DateComponents, previousStartingTime: String, previousEndingTime: String, set: Set<String>)
}

class EditCellTableViewController: UITableViewController {
    
    @IBOutlet weak var editTitleField: UITextField!
    
    @IBOutlet weak var editStartingTimeField: UITextField!
    
    @IBOutlet weak var editEndingTimeField: UITextField!
    
    @IBOutlet weak var editDescriptionField: UITextView!
    
    @IBOutlet weak var titleErrorLabel: UILabel!
    
    @IBOutlet weak var timeErrorLabel: UILabel!
    
    
    var delegate: EditScheduleDelegate?
    
    var cellToEdit: ScheduleCellDetails?
    
    let datePickerTime = UIDatePicker()
    var currentTextFieldName: UITextField?
    
    //creating Realm
    let realm = try! Realm()
    
    //notification
    var notificationComponent: DateComponents?
    
    //set for checking starting time repetition
    var startTimeSet:Set<String> = Set<String>()
    
    var prevStartingTime: String?
    var prevEndingTime: String?
    var prevDateComponent: DateComponents?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prevStartingTime = cellToEdit?.startingTime
        prevEndingTime = cellToEdit?.endingTime
        
        notificationComponent = prevDateComponent
        
        //print(prevDateComponent)
        
        editTitleField.text = cellToEdit?.title
        editStartingTimeField.text = cellToEdit?.startingTime
        editEndingTimeField.text = cellToEdit?.endingTime
        editDescriptionField.text = cellToEdit?.describe
        
        // layout design
        editTitleField.layer.cornerRadius = editTitleField.frame.size.height / 5
        
        editDescriptionField.layer.cornerRadius = editDescriptionField.frame.size.height / 10
        
        //delegates
        editStartingTimeField.delegate = self
        editEndingTimeField.delegate = self
        editTitleField.delegate = self
        
        //date picker mode
        datePickerTime.datePickerMode = .time
        
        //to dismiss the keyboard on tapping anywhere else
        hideKeyboardOnTap()
        
        //MARK: - To add a done button to TextView Keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit() //will fit to full screen
        
        //bar done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDescripton(sender:)))
        
        toolbar.setItems([doneButton], animated: true)
        
        //assign toolbar
        editDescriptionField.inputAccessoryView = toolbar
    }
    
    @objc func doneDescripton(sender: UIBarButtonItem){
        editDescriptionField.resignFirstResponder()
    }
    
    //MARK: - Date Picker as Time Functions
    func createDatePicker(textField: UITextField) {
        
        currentTextFieldName = textField
        //toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit() //will fit to full screen
        
        //bar done button
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
        
        if currentTextFieldName == editStartingTimeField {
            //notification
            notificationComponent = datePickerTime.calendar.dateComponents([.hour, .minute], from: datePickerTime.date)
        }
    }
    
    @objc func donePressed(sender: UIBarButtonItem) {
        
        //formatter
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        currentTextFieldName?.text = formatter.string(from: datePickerTime.date)
        
        if currentTextFieldName == editStartingTimeField {
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
    
    //MARK: - Segues
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        
        var check: Bool = true
        
        if editTitleField.text == "" {
            check = false
            titleErrorLabel.text = "Please add a title"
        } else {
            titleErrorLabel.text = ""
        }
        
        if editStartingTimeField.text == "" {
            check = false
            timeErrorLabel.text = "Please add a starting time"
        } else {
            
            if startTimeSet.contains(editStartingTimeField.text!) && editStartingTimeField.text != prevStartingTime {
                check = false
                timeErrorLabel.text = "This starting Time is already in use. Please add a different time"
            
            } else if editStartingTimeField.text == prevStartingTime {
                if check == true {
                    timeErrorLabel.text = ""
                }
            } else {
                startTimeSet.insert(editStartingTimeField.text!)
                
                if check == true {
                    timeErrorLabel.text = ""
                }
            }
        }
        
        if editEndingTimeField.text == "" {
            check = false
            timeErrorLabel.text = "Please add an ending time"
        } else {
            
            if check == true {
                timeErrorLabel.text = ""
            }
        }
        
        if check == true {
            updateRealm(cell: cellToEdit!)
            
            delegate?.editSchedule(cell: cellToEdit!, component: notificationComponent!, previousStartingTime: prevStartingTime!, previousEndingTime: prevEndingTime!, set: startTimeSet)
            
            dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Realm update
    
    func updateRealm(cell: ScheduleCellDetails) {
        
        do {
            try realm.write {
                cell.title = editTitleField.text!
                cell.startingTime = editStartingTimeField.text!
                cell.endingTime = editEndingTimeField.text!
                cell.describe = editDescriptionField.text
                cell.sortingTime = getSortingTime(from: editStartingTimeField.text!)
            }
        } catch {
            print("Error saving done status, \(error)")
        }
    }
    
    func getSortingTime(from timeString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        
        let date = dateFormatter.date(from: timeString)!
        return date
    }
}

//MARK: - TextField Delegate
extension EditCellTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == editStartingTimeField {
            createDatePicker(textField: textField)
        }
        else if textField == editEndingTimeField {
            createDatePicker(textField: textField)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

//    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

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


