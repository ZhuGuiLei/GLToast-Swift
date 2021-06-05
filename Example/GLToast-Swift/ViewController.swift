//
//  ViewController.swift
//  GLToast-Swift
//
//  Created by ZhuGuiLei on 06/05/2021.
//  Copyright (c) 2021 ZhuGuiLei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.tag = 0
//        GLProgressHUD.initConfig()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.tag = view.tag + 1
        let tag = view.tag % 8
        switch tag {
        case 1:
            GLProgressHUD.show("提示信息1")
        case 2:
            GLProgressHUD.show("提示信息2", tit: "标题")
        case 3:
            GLProgressHUD.showInfo("提示信息3info", tit: "标题")
        case 4:
            GLProgressHUD.showSuccess("提示信息4成功", tit: "标题")
        case 5:
            GLProgressHUD.showError("提示信息5失败", tit: "标题")
        case 6:
            GLProgressHUD.showIndicator("提示信息6失败", tit: "标题")
        case 7:
            GLProgressHUD.dismissOne()
        default:
            GLProgressHUD.dismissAll()
            break
        }
    }


}

