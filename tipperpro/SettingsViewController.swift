 //
 //  SettingsViewController.swift
 //  tipperpro
 //
 //  Created by santosh ajith gogi on 3/12/16.
 //  Copyright © 2016 santosh ajith gogi. All rights reserved.
 //
 
 import UIKit
 
 class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var defaultTipPercentage: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        changeToGradientBackground()
    }
    
    func changeToGradientBackground(){
        let color1 = UIColor(netHex:0xFF5722)
        let color2 = UIColor(netHex:0xE91E63)
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [color1.CGColor, color2.CGColor]
        self.view.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func closeView(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
    @IBAction func defaultTipPercentageChanged(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(defaultTipPercentage.selectedSegmentIndex, forKey: "defaultTipPercentage")
        defaults.setBool(true, forKey: "defaultTipPercentageChanged")
        defaults.synchronize()
    }
    
    
    
 }
