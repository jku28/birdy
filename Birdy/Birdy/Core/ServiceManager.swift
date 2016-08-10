
//
//  ServiceManager.swift
//  Birdy
//
//  Created by Vladimir Yevdokimov on 8/7/16.
//  Copyright © 2016 Magnet Inc. All rights reserved.
//

import UIKit

let baseUrl = "https://jk208.host.cs.st-andrews.ac.uk/birdwatch"


class ServiceManager: NSObject {

    static var loggedUser:User?
    static var users:[User] = []

    //MARK: - Auth and User

    class func login(login:String, password:String,callback:((success:Bool,error:NSError?)->())?) {
        let urlString = "\(baseUrl)/users/login/\(login)/\(password)"
        LoadRequest(urlString, uploadData:nil, success: { (data) in
            if let str = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {
                if str.containsString("403") {
                    if callback != nil { callback!(success:false,error:NSError(domain: "in-app", code: 10001, userInfo: [NSLocalizedDescriptionKey : "Forbidden (403)"]))}
                    return
                } else if str.containsString("502") {
                    if callback != nil { callback!(success:false,error:NSError(domain: "in-app", code: 10001, userInfo: [NSLocalizedDescriptionKey : "Bad gateway (502)"]))}
                    return
                } else if str.containsString("504") {
                    if callback != nil { callback!(success:false,error:NSError(domain: "in-app", code: 10001, userInfo: [NSLocalizedDescriptionKey : "Gateway Time-out (504)"]))}
                    return
                }

                let result = stringToBool(str)
                if result {
                    for user in users {
                        if user.userName == login {
                            loggedUser = user
                            break
                        }
                    }

                    if callback != nil { callback!(success:result,error:nil)}
                } else {
                    if callback != nil { callback!(success:false,error:NSError(domain: "server", code: 10001, userInfo: [NSLocalizedDescriptionKey : "Please check credentials"]))}
                }
            } else {
                if callback != nil { callback!(success:false,error:nil)}
            }
        }) { (error) in
            if callback != nil { callback!(success:false,error:error)}
        }
    }

    class func registerNew(user:User, callback:((success:Bool,error:NSError?)->())?) {
        let urlString = "\(baseUrl)/users/adduser"

        LoadRequest(urlString, uploadData: user.uploadData(), success: { (data) in

            loggedUser = user

            if callback != nil { callback!(success:true,error:nil) }

            }) { (error) in
                if callback != nil { callback!(success:false,error:error) }
        }
    }

    class func getUserList() {
        let urlString = "\(baseUrl)/users/userlist"

        LoadRequest(urlString, uploadData:nil, success: { (data) in
            users = []
            print("users \(NSString(data: data!, encoding: NSUTF8StringEncoding))")
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                guard let usersArray :NSArray = JSON as? NSArray else {
                    return
                }
                for dict in usersArray {
                    users.append(User(dataDictionary: dict as! NSDictionary))
                }

            } catch let error as NSError {
                print("\(error)")
            }
        }) { (error) in
            print("error \(error)")
        }
    }

    class func updatePassword (newPassword:String, callback:((success:Bool,error:NSError?)->())?) {
        ///changepassword/:username/:password
        let urlString = "\(baseUrl)/users/changepassword/\(loggedUser!.userId)/\(newPassword)"
        LoadRequest(urlString, uploadData:nil, success: { (data) in
            let str = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("pass updated \(str)")
            if callback != nil { callback!(success:true,error:nil) }
        }) { (error) in
            print("error \(error)")
            if callback != nil { callback!(success:false,error:error) }
        }
    }
    //MARK: - Birds

    class func getAllBirds(callback:(([Bird],NSError?)->())?) {
        let urlString = "\(baseUrl)/birds/birdlist"

        LoadRequest(urlString, uploadData:nil, success: { (data) in
            var birds:[Bird] = []
            print("got birds \(NSString(data: data!, encoding: NSUTF8StringEncoding))")
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                guard let birdsArray :NSArray = JSON as? NSArray else {
                    if callback != nil { callback!([],NSError(domain: "in-app", code: 1000, userInfo: [NSLocalizedDescriptionKey:"json not array"]))}
                    return
                }
                for dict in birdsArray {
                    birds.append(Bird(dataDictionary: dict as! NSDictionary))
                }
                if callback != nil { callback!(birds,nil)}
            } catch let error as NSError {
                print("\(error)")
                if callback != nil { callback!([],error)}
            }
        }) { (error) in
            if callback != nil { callback!([],error)}
        }
    }

    class func getBirdsList(callback:(([Bird],NSError?)->())?) {
        let urlString = "\(baseUrl)/birds/birdlist/\(loggedUser!.userId)"

        LoadRequest(urlString, uploadData:nil, success: { (data) in
            var birds:[Bird] = []
            print("got birds \(NSString(data: data!, encoding: NSUTF8StringEncoding))")
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                guard let birdsArray :NSArray = JSON as? NSArray else {
                    if callback != nil { callback!([],NSError(domain: "in-app", code: 1000, userInfo: [NSLocalizedDescriptionKey:"json not array"]))}
                    return
                }
                for dict in birdsArray {
                    birds.append(Bird(dataDictionary: dict as! NSDictionary))
                }
                if callback != nil { callback!(birds,nil)}
            } catch let error as NSError {
                print("\(error)")
                if callback != nil { callback!([],error)}
            }
        }) { (error) in
            if callback != nil { callback!([],error)}
        }
    }

    class func getRandomBird(callback:((bird:Bird?,error:NSError?)->())?) {
        let urlString = "\(baseUrl)/birds/randombird"

        LoadRequest(urlString, uploadData:nil, success: { (data) in
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                guard let birdsArray :NSArray = JSON as? NSArray else {
                    if callback != nil { callback!(bird: nil,error: NSError(domain: "in-app", code: 1000, userInfo: [NSLocalizedDescriptionKey:"json not array"]))}
                    return
                }
                let bird = Bird(dataDictionary: birdsArray.firstObject as! NSDictionary)
                if callback != nil { callback!(bird: bird,error: nil)}
            } catch let error as NSError {
                print("\(error)")
                if callback != nil { callback!(bird: nil,error: error)}
            }
            }, fail: {(error) in
                if callback != nil { callback!(bird: nil,error: error)}
        })
    }

    class func updateBird(birdId:String, vote:String, callback:((result:Bool,error:NSError?)->())?) {
        let encVote = vote.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let urlString = "\(baseUrl)/birds/updatebird/\(birdId)/\(encVote!)"
        LoadRequest(urlString, uploadData:nil, success: { (data) in
            let str = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("vote res \(str)")
            if callback != nil { callback!(result: true,error: nil)}

        }) { (error) in
            if callback != nil { callback!(result: false,error: error)}
        }
    }
}

//MARK: - Global

private func LoadRequest(urlString:String, uploadData:NSData?,success:((NSData?)->())?,fail:((NSError?)->())?) {
    let encodedStr = urlString//.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) as! String
    let request = NSMutableURLRequest(URL: NSURL(string: encodedStr)!)
    if uploadData != nil {
        request.HTTPMethod = "POST"
        request.HTTPBody = uploadData!
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                if error == nil {
                    if success != nil { success!(data!) }
                } else {
                    if fail != nil { fail!(error!) }
                }
            })
            }.resume()
    })
}

//MARK: - Additional classes

class Bird : NSObject {
    var birdId:String! = ""
    var image:String! = ""
    var scientificname:String! = ""
    var commonname:String! = ""
    var latitude:Double! = 0.0
    var longitude:Double! = 0.0
    var date:String! = ""
    var weather:String! = ""
    var status:String! = ""
    var votes:[[AnyObject!]]! = []
    var seenbyuser:[String]! = []
    var owner:String! = ""
    var comments:String! = ""

    init(dataDictionary:NSDictionary) {
        super.init()
        self.birdId = dataDictionary["_id"] as? String ?? ""
        self.image = dataDictionary["image"] as? String ?? ""
        self.scientificname = dataDictionary["scientificname"] as? String ?? ""
        self.commonname = dataDictionary["commonname"] as? String ?? ""
        if let locArr = dataDictionary["location"] as? NSArray {
            if let lat = locArr[0] as? Double {
                self.latitude = lat
            }
            if let long = locArr[1] as? Double {
                self.longitude = long
            }
        }

        self.date = dataDictionary["date"] as? String ?? ""
        self.weather = dataDictionary["weather"] as? String ?? ""
        self.status = dataDictionary["status"] as? String ?? ""
        self.votes = dataDictionary["votes"] as? [[AnyObject!]] ?? []
        self.seenbyuser = dataDictionary["seenbyuser"] as? [String] ?? []
        self.owner = dataDictionary["owner"] as? String ?? ""
        self.comments = dataDictionary["comments"] as? String ?? ""
    }


}

class User:NSObject {
    var userId:String! = ""
    var userName:String! = ""
    var fullName:String! = ""
    var email:String! = ""
    var password:String! = ""

    override init() {
        super.init()
    }

    init(dataDictionary:NSDictionary) {
        super.init()
        self.userId = dataDictionary[UserKey.Id.rawValue] as? String ?? ""
        self.userName = dataDictionary[UserKey.UserName.rawValue] as? String ?? ""
        self.fullName = dataDictionary[UserKey.FullName.rawValue] as? String ?? ""
        self.email = dataDictionary[UserKey.Email.rawValue] as? String ?? ""
        self.password = dataDictionary[UserKey.Password.rawValue] as? String ?? ""
    }

    func uploadData()-> NSData? {
        let dataDict = [UserKey.UserName.rawValue : self.userName,
                        UserKey.FullName.rawValue : self.fullName,
                        UserKey.Email.rawValue : self.email,
                        UserKey.Password.rawValue : self.password]

        do {
        let data = try NSJSONSerialization.dataWithJSONObject(dataDict, options: NSJSONWritingOptions.PrettyPrinted)
            return data

        } catch let error as NSError {
            print("user pasre error \(error)")
            return nil
        }
    }

    enum UserKey:String {
        case Id = "_id"
        case UserName = "username"
        case FullName = "fullname"
        case Email = "email"
        case Password = "password"
    }
}