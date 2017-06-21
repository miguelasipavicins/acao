//
//  WebViewViewController.swift
//  ChatChat
//
//  Created by Miguel Asipavicins on 07/02/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class WebViewViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let acaoUrl = URL(string: "http://acaocontabilidade.com/blog")
        let acaoUrlRequest = URLRequest(url: acaoUrl!)
        webView.loadRequest(acaoUrlRequest)
        navigationController?.navigationBar.isHidden = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
