//
//  ViewController.swift
//  TrackSDK
//
//  Created by Pranjal on 04/30/2021.
//  Copyright (c) 2021 Pranjal. All rights reserved.
//

import UIKit
import CherryAgent

class ViewController: UIViewController {

    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var message = UserDefaults.standard.integer(forKey: "crash")
        self.messageLabel.text = "View Loaded \n"
        if(message != nil){
            self.messageLabel.text = "Crash count : "+String(message)
        }
        print(UserDefaults.standard.string(forKey: "crash"))
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func onSubmitClicked(_ sender: Any) {
        let array = ["1","2"]
        print(array[3])
        if textField.text != ""{
            Event.init(eventName : "EVENT_"+textField.text!).setAttributes(attr: ["ATTR1" : "attr1"]).setData(data: ["DATA1" : ["SUBDATA1" : "subData1", "SUBDATA2" : "subData2"]]).send(response: {
                        response in
            
                        if(response.status == "Success"){
                            let alert = UIAlertController(title: "Alert", message: "Event EVENT_"+self.textField.text!+" has been registered successfully", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {_ in
                                self.textField.text = ""
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }else{
                            let alert = UIAlertController(title: "Alert", message: "Something went wrong. Please try again later", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {_ in
                                self.textField.text = ""
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
        }else{
            let alert = UIAlertController(title: "Enter Text", message: "", preferredStyle: .alert)
            self.present(alert, animated: false, completion: {
                let seconds = 4.0
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    alert.dismiss(animated: false, completion: nil)
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @objc func displayFCMToken(notification: NSNotification){
        guard let userInfo = notification.userInfo else {return}
//        if let fcmToken = userInfo["token"] as? String {
//          self.messageLabel.text = self.messageLabel.text!+"Received FCM token: \(fcmToken) \n"
//        }
      }
}

