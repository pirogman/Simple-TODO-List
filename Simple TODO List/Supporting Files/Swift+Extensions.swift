//
//  Swift+Extensions.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 02.04.2021.
//

import UIKit

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}

extension UIColor {
    static var randomLightFlatColor: UIColor {
        return UIColor(randomFlatColorOf: .light)
    }
}

extension TimeInterval {
    static var minute: TimeInterval { return TimeInterval(60) }
    static var hour: TimeInterval { return minute * 60 }
    static var day: TimeInterval { return hour * 24 }
    static var week: TimeInterval { return day * 7 }
    
    var minutes: Int { return Int((self / TimeInterval.minute)) }
    var hours: Int { return Int((self / TimeInterval.hour)) }
    var days: Int { return Int((self / TimeInterval.day)) }
    var weeks: Int { return Int((self / TimeInterval.week)) }
    
    func getTimeValues(minimumValidTime: TimeInterval = .minute) -> (isValid: Bool, weeks: Int, days: Int, hours: Int, minutes: Int, seconds: Double) {
        var seconds = self
        
        let weeks = seconds.weeks
        seconds -= TimeInterval.week * TimeInterval(weeks)
        
        let days = seconds.days
        seconds -= TimeInterval.day * TimeInterval(days)
        
        let hours = seconds.hours
        seconds -= TimeInterval.hour * TimeInterval(hours)
        
        let minutes = seconds.minutes
        seconds -= TimeInterval.minute * TimeInterval(minutes)
        
        return (self >= minimumValidTime, weeks, days, hours, minutes, seconds)
    }
}
