//
//  CameraViewController.swift
//  TableViewStory
//
//  Created by Developer on 3/30/17.
//  Copyright © 2017 Developer. All rights reserved.
//

/*
 Importand configurations to allow
 Add Privacy - Camera Usage Desc
 Add Privacy - Photo Library Usage
 
 The landscape photo won't work if the user has disabled the auto rotation
 
 
 */

import UIKit
import CoreData
import Alamofire


class CameraViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    // second part -- incorporating camera features
    // import the Alamofire
    // compile first and then add dependencies
    // first add the arguments and then add the file
    var imagePicker: UIImagePickerController!
    var imagesDirectoyPath: String!
    var images: [UIImage]!
    var titles: [String]!
    var newDir: String!
    
    var stringPassed = ""
    
    var statusCode = 0
    
    var urlPostPhoto = "http://row52.com/Api/V1/Vehicle/PostPhoto"
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var myLabel: UILabel!
    
    
    @IBAction func UploadPhoto(_ sender: Any) {
       UploadRequestwithAlamofire()
        
    }
    
    
    /*
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     if UIDevice.current.orientation.isLandscape{
     print("----------------")
     print("will turn to landscape")
     }else{
     print("----will turn to portrait-----")
     
     UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
     }
     }
     */
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        myLabel.text = stringPassed
        // add asynchronous call for speed
        getLocalFolder()
        //let value = UIInterfaceOrientationMask.landscapeLeft.rawValue
        //UIDevice.current.setValue(value, forKey: "orientation")
        launchCamera()
        
    }
    // fix in landscape mode
//    private func supportedInterfaceOrientaion() -> UIInterfaceOrientationMask{
//        return UIInterfaceOrientationMask.landscapeLeft
//    }
//    private func shouldAutorotate() -> Bool{
//        return false
//    }
//    
    /*
     Upload photo requirements
     - get token from cache
     - add basic Authentication
     Authentication: Spider + token
     - Attach file
     - Execute request
     */
    
    func UploadRequestwithAlamofire(){
        print("Uploading process started.......")
        
        //  get token from session
        
        let preferences = UserDefaults.standard
        var myLocalSession: String = ""
        if let mySession = preferences.value(forKey: "session"){
            myLocalSession = mySession as! String
            print("Firt flag -- check session --get session UserDefault")
        }
        
        
        myLocalSession = String(myLocalSession.characters.dropLast())
        myLocalSession = String(myLocalSession.characters.dropFirst())
        
        let token = "Spider " + myLocalSession
        print(token)
        //forHTTPHeaderField: "Authorization")
        
        var parameters = [String: String]()
        parameters = [ "Authorization": token]
        print(parameters)
        
        
        // check the string is not empty and pass the value in the function
        let urlPostPhoto = self.urlPostPhoto + "?" + "barcode=" + stringPassed
        let tempImage = imageView.image
        
        if(tempImage == nil){
            return
        }
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(UIImageJPEGRepresentation(tempImage!, 0.8)!, withName: "Pic", fileName: "testFile.jpeg", mimeType: "image/jpeg")
            // to add the body to the request
            /*
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            */
        },  usingThreshold:UInt64.init(),
            to: urlPostPhoto,
            method: .post,
            headers:["Authorization": token]
            )
        {
            (result) in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress( closure: { (Progress) in
                    print("Upload Porgress: \(Progress.fractionCompleted)")
                })
                upload.responseJSON{ response in
                    //print(response.request)
                    print("Printing response ************")
                    print(response.response)
                    print(response.data)
                    print(response.result)
                    
                    self.statusCode = (response.response?.statusCode)!
                    
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                    }
                }
            case .failure( let encodingError):
                print("Printing error here ******\(encodingError)")
                if (self.statusCode == 401){
                    print("User needs to Log In")
                }
                
            }
        }
    }
    
    
    func launchCamera(){
        // creates an object of type UIImagePikcerController and and set the type to camera
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        //imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            
            // try to connect to the local directory
            // add timestamp to differentiate between files
            //write to file here
            /*
             let mediaType = info[UIImagePickerControllerOriginalImage]
             self.dismiss(animated:true, completion: nil)
             */
            imageView.image = image
            
            var imagePath = NSDate().description
            
            imagePath = imagePath.replacingOccurrences(of: " ", with: "")
            
            
            imagePath = newDir.appending("/\(imagePath).jpeg")
            
            print("Real path: \(imagePath)")
            
            //add the barcode, path and date to db
            // check none of them are null
            
            // turning into binary to save it into the file system
            let data = UIImageJPEGRepresentation(image, 80)
            
            let success = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
            
            //saving the carInfo to the local db
            if success && stringPassed != ""{
                guard let AppDelegate = UIApplication.shared.delegate as? AppDelegate else{
                    return
                }
                let managedContext = AppDelegate.persistentContainer.viewContext
                
                let entity = NSEntityDescription.entity(forEntityName: "CarInfo", in: managedContext)!
                
                let carInfo = NSManagedObject(entity: entity, insertInto: managedContext)
                
                let timeStamp = Date()
                
                carInfo.setValue(stringPassed, forKey: "barcode")
                carInfo.setValue(imagePath, forKey: "pathtofile")
                carInfo.setValue(timeStamp, forKey: "date")
                print("************")
                print("file saved to db")
                
                do{
                    try managedContext.save()
                    //people.append(person)
                }catch let error as NSError{
                    print(error.userInfo)
                }
            }
            
            do{
                titles = try FileManager.default.contentsOfDirectory(atPath: newDir)
                for title in titles{
                    print(title)
                }
            }catch{
                print("Error")
            }
            
            
        }
        else{
            print("Something went wrong")
        }
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func getLocalFolder(){
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        let docsURL = dirPaths[0]
        
        //let newDir = docsURL.appendingPathComponent("ImagePicker").path
        
        newDir = docsURL.appendingPathComponent("ImagePicker").path
        
        var objcbool: ObjCBool = true
        print(docsURL)
        let isExist = filemgr.fileExists(atPath: newDir, isDirectory: &objcbool)
        
        if isExist == false{
            do{
                try filemgr.createDirectory(atPath: newDir, withIntermediateDirectories: true, attributes: nil)
                print("File created")
                // check the path exists
                print(newDir)
            }catch let error as NSError{
                print("Error: \(error.localizedDescription)")
            }
        }
        else{
            print("Exist already")
            do{
                let fileList = try filemgr.contentsOfDirectory(atPath: "/")
                for filename in fileList{
                    print(filename)
                }
            }catch let error as NSError{
                print("Error: \(error.localizedDescription)")
            }
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
