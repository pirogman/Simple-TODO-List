//
//  SimpleAlertViewController.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 06.04.2021.
//

import UIKit

class SimpleAlertViewController: KeyboardHandlingViewController {
    
    /// Action to perform when add button clicked
    var action: ((_ name: String?) -> Void)?
    
    /// Action button title text
    var actionTitle: String?
    
    /// Initial text to put in input text field
    var initialText: String?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func buttonTap(_ sender: UIButton) {
        if sender == addButton {
            action?(inputField.text)
            dismiss(animated: true)
        } else if sender == cancelButton {
            dismiss(animated: true)
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

extension SimpleAlertViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
