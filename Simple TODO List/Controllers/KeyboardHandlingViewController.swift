//
//  KeyboardHandlingViewController.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 05.04.2021.
//

import UIKit

class KeyboardHandlingViewController: UIViewController {
    
    /// UIScrollView responsible for moving stuff up when keyboard shows up
    ///- Children should override this property and return a valid UIScrollView in order to handle keyboard show/hide cases
    ///- Also call both viewWillAppear & viewDidDisappear to actually register for notifications
    var backgroundScrollView: UIScrollView? { return nil }
    
    // MARK: - Register to Keyboard Notifications
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Subscribe for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowOrHide), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowOrHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHidden), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Unsubscribe from keyboard notifications
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    // MARK: - Determining Keyboard State
    
    private(set) var isKeyboardUp = false
    
    /// Records if keyboard did appear
    @objc private func keyboardShown() {
        isKeyboardUp = true
    }
    
    /// Records if keyboard did hide
    @objc private func keyboardHidden() {
        isKeyboardUp = false
    }
    
    // MARK: - Handling Keyboard
    
    /// Forcefully hides keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /// Handles keyboard showing and hiding
    @objc private func keyboardWillShowOrHide(notification: NSNotification) {
        // Get required info out of the notification
        if let scrollView = backgroundScrollView, let userInfo = notification.userInfo, let endValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey], let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey], let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {
            
            // Transform the keyboard's frame into our view's coordinate system
            let endRect = view.convert((endValue as AnyObject).cgRectValue, from: view.window)
            
            // Find out how much the keyboard overlaps our scroll view
            let keyboardOverlap = scrollView.frame.maxY - endRect.origin.y
            
            // Set the scroll view's content inset & scroll indicator to avoid the keyboard
            scrollView.contentInset.bottom = keyboardOverlap
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardOverlap
            
            // Scroll to try preserve view center
            let movedOrigin = CGPoint(x: endRect.origin.x, y: endRect.origin.y - keyboardOverlap / 2)
            let centeredRect = CGRect(origin: movedOrigin, size: endRect.size)
            scrollView.scrollRectToVisible(centeredRect, animated: true)
            
            // Animate reallocation
//            let duration = (durationValue as AnyObject).doubleValue
//            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
//            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
//                self.view.layoutIfNeeded()
//            }, completion: nil)
        }
    }
    
}
