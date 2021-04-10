//
//  DateAlertViewController.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 05.04.2021.
//

import UIKit

class DateAlertViewController: KeyboardHandlingViewController {
    
    /// Action to perform when add button clicked
    var action: ((_ name: String?, _ dueDate: Date?) -> Void)?
    
    /// Action button title text
    var actionTitle: String?
    
    /// Initial text to put in input text field
    var initialText: String?
    
    /// Initial date to put in date picker
    var initialDate: Date?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var switchHintLabel: UILabel!
    @IBOutlet weak var dateSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func buttonTap(_ sender: UIButton) {
        if sender == addButton {
            action?(inputField.text, dateSwitch.isOn ? datePicker.date : nil)
            dismiss(animated: true)
        } else if sender == cancelButton {
            dismiss(animated: true)
        }
    }
    
    @IBAction func switchTap(_ sender: UISwitch) {
        if !isKeyboardUp {
            showDatePicker(sender.isOn)
        }
    }
    
    private func showDatePicker(_ show: Bool, duration: TimeInterval = 0.6) {
        if show {
            if !datePicker.isHidden { return }
            UIView.animate(
                withDuration: duration,
                delay: 0.0,
                options: [.curveEaseOut],
                animations: {
                    self.datePicker.alpha = 1.0
                    self.datePicker.isHidden = false
            })
        } else {
            if datePicker.isHidden { return }
            datePicker.alpha = 0.0
            UIView.animate(
                withDuration: duration,
                delay: 0.0,
                options: [.curveEaseOut],
                animations: {
                    self.datePicker.isHidden = true
            })
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup initial data
        addButton.setTitle(actionTitle ?? "Action", for: .normal)
        inputField.text = initialText
        datePicker.date = initialDate ?? Date()
        dateSwitch.isOn = initialDate != nil
        
        // Hide date picker if not needed
        showDatePicker(dateSwitch.isOn)

        // Configure input text field
        inputField.returnKeyType = .done
        inputField.delegate = self
        
        // Make rounded
        alertView.layer.cornerRadius = 12.0
        addButton.layer.cornerRadius = 12.0
        cancelButton.layer.cornerRadius = 12.0
        addButton.layer.borderWidth = 2.0
        cancelButton.layer.borderWidth = 2.0
        addButton.layer.borderColor = UIColor.lightGray.cgColor
        cancelButton.layer.borderColor = UIColor.lightGray.cgColor
        
        // Add tap gesture recognizer to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = true
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Keyboard
    
    override var backgroundScrollView: UIScrollView? {
        return scrollView
    }
    
    override func dismissKeyboard() {
        super.dismissKeyboard()
        
        showDatePicker(dateSwitch.isOn)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        inputField.becomeFirstResponder()
    }
    
}

// MARK: - UITextFieldDelegate

extension DateAlertViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showDatePicker(false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        showDatePicker(dateSwitch.isOn)
        return true
    }
    
}
