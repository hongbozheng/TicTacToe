//
//  TTTImageView.swift
//  TicTacToe
//
//  Created by hongbozheng on 12/28/16.
//  Copyright © 2016 fiu. All rights reserved.
//

import UIKit

class TTTImageView: UIImageView {

    var player:String?
    var activated:Bool! = false
    
    func setPlayer(_player:String){
     self.player = _player
        if activated == false{
            if _player == "x"{
                self.image = UIImage(named:"x")
            }else{
                self.image = UIImage(named:"o")
            }
            activated = true
        }
    }
}
