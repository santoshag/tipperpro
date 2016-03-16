//
//  ViewController.swift
//  tipperpro
//
//  Created by santosh ajith gogi on 3/12/16.
//  Copyright © 2016 santosh ajith gogi. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import AddressBookUI

class ViewController: UIViewController, CLLocationManagerDelegate  {
    
    @IBOutlet weak var billField: UITextField!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var tipPercentage: UISegmentedControl!
    @IBOutlet weak var splitInsightsSegment: UISegmentedControl!
    @IBOutlet weak var plusSymbolLabel: UILabel!
    @IBOutlet weak var equalsSymbolLabel: UILabel!
    @IBOutlet weak var startHelpLabel: UILabel!
    @IBOutlet weak var splitBillBy2: UILabel!
    @IBOutlet weak var splitBillBy3: UILabel!
    @IBOutlet weak var splitBillBy4: UILabel!
    @IBOutlet weak var splitBillFaces2: UILabel!
    @IBOutlet weak var splitBillFaces3: UILabel!
    @IBOutlet weak var splitBillFaces4: UILabel!
    @IBOutlet weak var saveTipButton: UIButton!
    @IBOutlet weak var insightsLabel: UILabel!
    
    var saveTip = false
    let locationManager = CLLocationManager()
    let tipPercentages = [0.15, 0.20, 0.25]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        //register observers for bill amount across app restarts
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        applicationWillEnterForeground()
        
        initializeViewElements()
        
    }
    
    
    func initializeViewElements(){
        changeToGradientBackground()
        setBillFieldLocalCurrencyPlaceHolder()
        loadInsights()
    }
    
    //set locale based currency symbol
    func setBillFieldLocalCurrencyPlaceHolder(){
        let locale = NSLocale.currentLocale()
        if let currencySymbol = locale.objectForKey(NSLocaleCurrencySymbol) as? String {
            billField.placeholder = currencySymbol
        }
    }
    
    
    func changeToGradientBackground(){
        let color1 = UIColor(netHex:0xFF5722)
        let color2 = UIColor(netHex:0xE91E63)
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [color1.CGColor, color2.CGColor]
        self.view.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    
    func loadInsights(){
        let(lat, long) = getCurrentLatLong()
        reverseGeocoding(lat, longitude: long)
    }
    
    
    //function to save the tip for analytics.
    @IBAction func saveTip(sender: AnyObject) {
        saveTip = true
        loadInsights()
    }
    
    
    //get current location latitude and longitude using geocoding from apple maps
    //ref: http://mhorga.org/2015/08/14/geocoding-in-ios.html
    func getCurrentLatLong() -> (
        CLLocationDegrees,
        CLLocationDegrees){
            let locManager = CLLocationManager()
            // Core Location Manager asks for GPS location
            locManager.delegate = self
            locManager.desiredAccuracy = kCLLocationAccuracyBest
            locManager.requestWhenInUseAuthorization()
            locManager.startMonitoringSignificantLocationChanges()
            
            // Check if the user allowed authorization
            if   (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways)
            {
                if locManager.location != nil{
                    return((locManager.location?.coordinate.latitude)!, (locManager.location?.coordinate.longitude)!)
                }
            }
            //return empty CLLocationDegrees if location not found
            return(CLLocationDegrees(), CLLocationDegrees())
    }
    

    //location and address will be reported to this function from reverse geocoding closure
    func locationAddress(address:String, interestArea:String){
        var locationKey = String()
        if interestArea.isEmpty{
            locationKey = address
        }else{
            locationKey = interestArea + " " + address
        }
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if saveTip{
            //we store 2 items in the persistence storage 1. number of times visited to current location
            //2. average tip percentage
            let numberOfVisitsToCurrentLocation = defaults.integerForKey(locationKey)
            defaults.setObject(numberOfVisitsToCurrentLocation + 1, forKey: locationKey)
            
            var averageTip = Double()
            if let lastAverageTip = defaults.objectForKey(locationKey+"AverageTip"){
                
                print("lastAverageTip:\(lastAverageTip) numberOfVisitsToCurrentLocation: \(numberOfVisitsToCurrentLocation)")
                averageTip = ((lastAverageTip as! Double * Double(numberOfVisitsToCurrentLocation)) + (tipPercentages[tipPercentage.selectedSegmentIndex]*100)) / Double(numberOfVisitsToCurrentLocation + 1)
            }else{
                print("lastAverageTip: is zero")
                if numberOfVisitsToCurrentLocation == 0{
                    averageTip = (tipPercentages[tipPercentage.selectedSegmentIndex]*100)
                }else{
                    averageTip = (tipPercentages[tipPercentage.selectedSegmentIndex]*100) / Double(numberOfVisitsToCurrentLocation)
                }
                
            }
            
            print("averageTip:\(averageTip)")
            defaults.setObject(averageTip, forKey: locationKey+"AverageTip")
            defaults.synchronize()
        }
        
        saveTip = false
        var insightString = String()
        //load insights
        let numberOfVisitsToCurrentLocation = defaults.integerForKey(locationKey)
        let averageTip = defaults.doubleForKey(locationKey+"AverageTip")
        print("locationKey: \(locationKey) numberOfVisitsToCurrentLocation\(numberOfVisitsToCurrentLocation)")
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let averageTipStr = formatter.stringFromNumber(averageTip)!
        switch numberOfVisitsToCurrentLocation{
        case 0: insightString = "You are at \(locationKey).\nThis is your first visit to this outlet. Hope you are having a good time."
        case 1: insightString = "You are at \(locationKey).\nYou have visited this outlet one time before and had tipped \(averageTipStr)%."
        default: insightString = "You are at \(locationKey).\nYou have visited this place many times before.\nYour average tip at this outlet is \(averageTipStr)%."
        }
        insightsLabel.text = insightString
        
    }
    
    //function to find the address and name of the outlet using reverse geocoding
    func reverseGeocoding(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        var address = String()
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print(error)
            }
            else if placemarks?.count > 0 {
                let pm = placemarks![0]
                address = ABCreateStringWithAddressDictionary(pm.addressDictionary!, false)
                
                var interestArea = String()
                if pm.areasOfInterest?.count > 0 {
                    let areaOfInterest = pm.areasOfInterest?[0]
                    interestArea = areaOfInterest!
                } else {
                    print("No area of interest found.")
                }
                self.locationAddress(address, interestArea:interestArea)
                
                
            }
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func choseSplitOrInsights(sender: AnyObject) {
        var splitFieldsAlpha = 0
        var insightFieldsLabelAlpha = 1
        if(splitInsightsSegment.selectedSegmentIndex == 1){
            splitFieldsAlpha = 1
            insightFieldsLabelAlpha = 0
        }
        UIView.animateWithDuration(0.2){
            self.splitBillBy2.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillBy3.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillBy4.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillFaces2.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillFaces3.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillFaces4.alpha = CGFloat(splitFieldsAlpha)
            self.insightsLabel.alpha = CGFloat(insightFieldsLabelAlpha)
            
        }
        
    }
    
    func changeVisibility(hidden: Bool){
        var alpha = 0
        var helpTextAlpha = 1
        var splitFieldsAlpha = 1
        var insightFieldsLabelAlpha = 0
        
        
        if !hidden{
            alpha = 1
            helpTextAlpha = 0
            if splitInsightsSegment.selectedSegmentIndex == 0{
                splitFieldsAlpha = 0
                insightFieldsLabelAlpha = 1
            }
        }
        
        UIView.animateWithDuration(0.2) {
            self.tipLabel.alpha = CGFloat(alpha)
            self.totalLabel.alpha = CGFloat(alpha)
            self.tipPercentage.alpha = CGFloat(alpha)
            self.plusSymbolLabel.alpha = CGFloat(alpha)
            self.splitInsightsSegment.alpha = CGFloat(alpha)
            self.equalsSymbolLabel.alpha = CGFloat(alpha)
            self.startHelpLabel.alpha = CGFloat(helpTextAlpha)
            self.splitBillBy2.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillBy3.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillBy4.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillFaces2.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillFaces3.alpha = CGFloat(splitFieldsAlpha)
            self.splitBillFaces4.alpha = CGFloat(splitFieldsAlpha)
            self.insightsLabel.alpha = CGFloat(insightFieldsLabelAlpha)
            self.saveTipButton.alpha = CGFloat(insightFieldsLabelAlpha)
        }
    }
    
    //action function called when user edits bill field
    @IBAction func billEditChanged(sender: AnyObject) {
        
        if let billAmount = Double(billField.text!){
            changeVisibility(false)
            calculateNewBill()
        }else{
            changeVisibility(true)
        }
    }
    
    
    func calculateNewBill(){
        var tipPercent = 0.0
        let defaults = NSUserDefaults.standardUserDefaults()
        
        //2 scenarios for tip percentage changes. one in settings and other in main userview selection.
        let defaultTipPercentageChanged = defaults.boolForKey("defaultTipPercentageChanged")
        if defaultTipPercentageChanged {
            
            let defaultTipValue = defaults.integerForKey("defaultTipPercentage")
            tipPercentage.selectedSegmentIndex = defaultTipValue
            tipPercent = tipPercentages[defaultTipValue]
            defaults.setBool(false, forKey: "defaultTipPercentageChanged")
            defaults.synchronize()
            
        }else{
            tipPercent = tipPercentages[tipPercentage.selectedSegmentIndex]
        }
        
        
        if let billAmount = Double(billField.text!){
            let tip = Double(tipPercent) * billAmount
            let total = tip + billAmount
            setTipAndTotal(tip, total: total)
        }
    }
    
    //format currency code according to current locale - (.currentlocale) is already set.
    func setTipAndTotal(tip: Double, total:Double){
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        tipLabel.text = formatter.stringFromNumber(tip)
        totalLabel.text = formatter.stringFromNumber(total)
        splitBillBy2.text = formatter.stringFromNumber(total/2)
        splitBillBy3.text = formatter.stringFromNumber(total/3)
        splitBillBy4.text = formatter.stringFromNumber(total/4)
    }

    //handle gesture recognition: tap anywhere to hide the keyboard
    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    
    //always show the keyboard first when application is first opened - make keyboard first responder
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        billField.becomeFirstResponder()
        //check if application restart is less than 10 min to restore last entered bill, tip and total values
        calculateNewBill()
    }
    
    //restore last entered bill, tip and total values from the persistence storage
    func applicationWillEnterForeground() {
        // Do any additional setup after loading the view, typically from a nib.
        let defaults = NSUserDefaults.standardUserDefaults()
        if let lastVisitDate = defaults.objectForKey("lastVisitDate"){
            let elapsedTime = NSDate().timeIntervalSinceDate(lastVisitDate as! NSDate)
            let billWhenLastVisited = defaults.objectForKey("billWhenLastVisited") as! String
            if elapsedTime/60 <= 10.0{
                //restore the last bill
                if !billWhenLastVisited.isEmpty{
                    billField.text = billWhenLastVisited
                    changeVisibility(false)
                }
            }else{
                setTipAndTotal(0.0, total:0.0)
            }
            
        }
    }
    
    //store date and bill fields in persistence storage for app restart restoration of bill and other fields
    func applicationWillEnterBackground(notification: NSNotification) {
        //store date for returning users within 10 min
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(NSDate(), forKey: "lastVisitDate")
        defaults.setObject(billField.text!, forKey: "billWhenLastVisited")
        defaults.synchronize()
    }
}


//convert hex color to UIColor objects for background color
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

