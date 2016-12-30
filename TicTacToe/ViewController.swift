//
//  ViewController.swift
//  TicTacToe
//
//  Created by hongbozheng on 12/28/16.
//  Copyright © 2016 fiu. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController,MCBrowserViewControllerDelegate {

    @IBOutlet var fields: [TTTImageView]!
    var currentPlayer:String!
    var appDelegate:AppDelegate!
    var rivalInputed:Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mpcHandler.setupPeerWithDisplayName(displayName: UIDevice.current.name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(advertise: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.peerChangedStateWithNotification(_:)), name: NSNotification.Name(rawValue:"MPC_DidChangeStateNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleReceivedDataWithNotification(_:)), name: NSNotification.Name(rawValue:"MPC_DidReceiveDataNotification"), object: nil)
        setupField()
    currentPlayer = "x"
    }
    func resetField() {
        for index in 0 ... fields.count - 1 {
            fields[index].image = nil
            fields[index].activated = false
            fields[index].player = ""
        }
        currentPlayer = "x"
    }
    
    
    
    func setupField() {
        for index in 0 ... fields.count - 1 {
            let gestureRecongnizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.fieldTapped(_:)))
            gestureRecongnizer.numberOfTapsRequired = 1
            fields[index].addGestureRecognizer(gestureRecongnizer)
        }
    }

    @IBAction func newGame(_ sender: AnyObject) {
        resetField()
        let messageDict = ["string":"New Game"]
        
        do {
         let messageData =   try JSONSerialization.data(withJSONObject: messageDict, options: .prettyPrinted)
            
            do {
                try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
            } catch  {
                 print("newGame send data error ==\(error.localizedDescription)")
            }
            
            
        } catch  {
            print("newGame error ==\(error.localizedDescription)")
        }
        
    }
    
    @IBAction func connect(_ sender: AnyObject) {
        if appDelegate.mpcHandler.session != nil {
            appDelegate.mpcHandler.setupBrowser()
            appDelegate.mpcHandler.browser.delegate = self
            self.present(appDelegate.mpcHandler.browser, animated: true, completion: nil)
        }
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
    func peerChangedStateWithNotification(_ notification:Notification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.object(forKey: "state") as? Int
        if state == MCSessionState.connected.rawValue {
            self.navigationItem.title = "Connected"
        }
    }

    func handleReceivedDataWithNotification(_ notification:Notification){
      let userInfo = notification.userInfo
        let receivedData:Data = userInfo!["data"] as! Data
        do {
            let message = try JSONSerialization.jsonObject(with: receivedData, options: .allowFragments) as! [String : Any]
            let senderPeerId: MCPeerID = userInfo!["peerID"] as! MCPeerID
            let senderDisplayName = senderPeerId.displayName
            
            print("message==\(message)");
            if (message["string"] as AnyObject).isEqual("New Game") {
               let alert = UIAlertController(title: "TicTacToe", message: "\(senderDisplayName) has started a new game", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                resetField()
            }else{
                let field:Int? = message["field"] as! Int?
                let player:String = message["player"] as! String
                
                if field != nil && player != nil{
                fields[field!].player = player
                    fields[field!].setPlayer(_player: player)
                    rivalInputed = true
                    if player == "x"{
                    currentPlayer = "o"
                    }else{
                     currentPlayer = "x"
                    }
                    checkResults()
                }
            }
        } catch  {
            print("errors:\(error.localizedDescription)")
        }
    }
    
    
    func fieldTapped(_ recognizer:UITapGestureRecognizer) {
        
        if  self.navigationItem.title != "Connected"  {
            let alert = UIAlertController(title: "Tic Tac Toe", message: "Please find a rival first.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alert:UIAlertAction!) -> Void in
            }))
            
            self.present(alert, animated: true, completion: nil)

           return
        }
        
        if !rivalInputed {
        return
        }
        rivalInputed = false
        let tappedField = recognizer.view as! TTTImageView
        tappedField.setPlayer(_player: currentPlayer)
        let messageDict = ["field":tappedField.tag - 1,"player":currentPlayer] as [String:Any]

        do {
           let messageData =  try JSONSerialization.data(withJSONObject: messageDict, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            do {
//                print("appDelegate.mpcHandler.session.connectedPeers==\(appDelegate.mpcHandler.session.connectedPeers)")
                try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
                
                checkResults()
            } catch  {
                print("fieldTapped send message data error:\(error.localizedDescription)")
            }

        } catch  {
             print("fieldTapped JSONSerialization data error: \(error.localizedDescription)")
        }
    }

    func checkResults() {
        var winner = ""
        
        if fields[0].player == "x" && fields[1].player == "x" && fields[2].player == "x"{
            winner = "x"
        }else if fields[0].player == "o" && fields[1].player == "o" && fields[2].player == "o"{
            winner = "o"
        }else if fields[3].player == "x" && fields[4].player == "x" && fields[5].player == "x"{
            winner = "x"
        }else if fields[3].player == "o" && fields[4].player == "o" && fields[5].player == "o"{
            winner = "o"
        }else if fields[6].player == "x" && fields[7].player == "x" && fields[8].player == "x"{
            winner = "x"
        }else if fields[6].player == "o" && fields[7].player == "o" && fields[8].player == "o"{
            winner = "o"
        }else if fields[0].player == "x" && fields[3].player == "x" && fields[6].player == "x"{
            winner = "x"
        }else if fields[0].player == "o" && fields[3].player == "o" && fields[6].player == "o"{
            winner = "o"
        }else if fields[1].player == "x" && fields[4].player == "x" && fields[7].player == "x"{
            winner = "x"
        }else if fields[1].player == "o" && fields[4].player == "o" && fields[7].player == "o"{
            winner = "o"
        }else if fields[2].player == "x" && fields[5].player == "x" && fields[8].player == "x"{
            winner = "x"
        }else if fields[2].player == "o" && fields[5].player == "o" && fields[8].player == "o"{
            winner = "o"
        }else if fields[0].player == "x" && fields[4].player == "x" && fields[8].player == "x"{
            winner = "x"
        }else if fields[0].player == "o" && fields[4].player == "o" && fields[8].player == "o"{
            winner = "o"
        }else if fields[2].player == "x" && fields[4].player == "x" && fields[6].player == "x"{
            winner = "x"
        }else if fields[2].player == "o" && fields[4].player == "o" && fields[6].player == "o"{
            winner = "o"
        }
        
        if winner != ""{
            let alert = UIAlertController(title: "Tic Tac Toe", message: "The winner is \(winner)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alert:UIAlertAction!) -> Void in
                self.resetField()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }

    }
    
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

