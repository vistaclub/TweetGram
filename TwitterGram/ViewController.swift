//
//  ViewController.swift
//  TwitterGram
//
//  Created by Jason Wong on 2018-06-22.
//  Copyright © 2018 Jason Wong. All rights reserved.
//

import Cocoa
import OAuthSwift
import SwiftyJSON
import Kingfisher


class ViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var loginLogoutButton: NSButton!
    
    var imageURLs : [String] = []
    var tweetURLs : [String] = []
    
    // create an instance and retain it
    let oauthswift = OAuth1Swift(
        consumerKey:    "OfEFYiDq8UJ5XVOQeUiauuZYM",
        consumerSecret: "bj4v1U8sko3zRpudon8hMhWarnfJg5Lzgvuh0iGJhZbVkkDOPp",
        requestTokenUrl: "https://api.twitter.com/oauth/request_token",
        authorizeUrl:    "https://api.twitter.com/oauth/authorize",
        accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 300, height: 300)
        layout.sectionInset = EdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        layout.minimumLineSpacing = 5.0
        layout.minimumInteritemSpacing = 5.0
        collectionView.collectionViewLayout = layout
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        checkLogin()
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "TwitterGramItem", for: indexPath)
        let urlString = imageURLs[indexPath.item]
        let url = URL(string: urlString)
        item.imageView?.kf.setImage(with: url)
        
        return item
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectAll(nil)
        if let indexPath = indexPaths.first {
            if let url = URL(string: tweetURLs[indexPath.item]) {
                NSWorkspace.shared().open(url)
            }
        }
    }
    
    func checkLogin() {
        if let oauthToken = UserDefaults.standard.string(forKey: "oauthToken") {
            if let oauthTokenSecret = UserDefaults.standard.string(forKey: "oauthTokenSecret") {
                
                oauthswift.client.credential.oauthToken = oauthToken
                oauthswift.client.credential.oauthTokenSecret = oauthTokenSecret
                
                self.getTweets()
                loginLogoutButton.title = "Logout"
            }
        }
    }
    
    @IBAction func loginLogoutClicked(_ sender: Any) {
        if loginLogoutButton.title == "Login" {
            TwitterLogin()
        } else {
            TwitterLogOut()
        }
    }
    
    func TwitterLogOut() {
        loginLogoutButton.title = "Login"
        UserDefaults.standard.removeObject(forKey: "oauthToken")
        UserDefaults.standard.removeObject(forKey: "oauthTokenSecret")
        UserDefaults.standard.synchronize()
        imageURLs = []
        tweetURLs = []
        collectionView.reloadData()
    }
    
    func TwitterLogin() {
        // authorize
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "localhost://")!,
            success: { credential, response, parameters in
                UserDefaults.standard.set(credential.oauthToken, forKey: "oauthToken")
                UserDefaults.standard.set(credential.oauthTokenSecret, forKey: "oauthTokenSecret")
                UserDefaults.standard.synchronize()
                // print(parameters["user_id"] as Any)
                // Do your request
                self.loginLogoutButton.title = "Logout"
                self.getTweets()
        },
            failure: { error in
                // print(error.localizedDescription)
                print()
        }
        )
    }
    
    func getTweets() {
        
        let _ = oauthswift.client.get("https://api.twitter.com/1.1/statuses/home_timeline.json", parameters: ["tweet_mode":"extended","count":200],
                                      success: { response in
                                        /* if let dataString = response.string {
                                         print(dataString)
                                         } */
                                        let json = JSON(data: response.data)
                                        
                                        // var imageURLs : [String] = []
                                        
                                        // If json is .Array
                                        // The `index` is 0..<json.count's string value
                                        for (_,tweetJSON):(String, JSON) in json {
                                            // Do something you want
                                            var retweeted = false
                                            for (_,mediaJSON):(String, JSON) in
                                                tweetJSON["retweeted_status"]["entities"]["media"] {
                                                    retweeted = true
                                                    if let url = mediaJSON["media_url_https"].string {
                                                        self.imageURLs.append(url)
                                                    }
                                                    if let expandedURL = mediaJSON["expanded_url"].string {
                                                        self.tweetURLs.append(expandedURL)
                                                    }
                                            }
                                            if retweeted == false {
                                                for (_,mediaJSON):(String, JSON) in
                                                    tweetJSON["extended_entities"]["media"] {
                                                        if let url = mediaJSON["media_url_https"].string {
                                                            self.imageURLs.append(url)
                                                        }
                                                        if let expandedURL = mediaJSON["expanded_url"].string {
                                                            self.tweetURLs.append(expandedURL)
                                                        }
                                                }
                                            }
                                        }
                                        print(self.imageURLs)
                                        self.collectionView.reloadData()
        },
                                      failure: { error in
                                        print(error)
        }
        )
        
    }
}

