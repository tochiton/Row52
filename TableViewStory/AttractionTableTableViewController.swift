//
//  AttractionTableTableViewController.swift
//  TableViewStory
//
//  Created by Developer on 2/7/17.
//  Copyright © 2017 Developer. All rights reserved.
//

/*
 Table View Controller
 
 */


import UIKit
import CoreData
import Alamofire


class AttractionTableTableViewController: UITableViewController {
    
    //    var attractionImages = [String]()
    //    var attractionNames = [String]()
    //    var webAddresses = [String]()
    
    var listOfCars: [NSManagedObject] = []
    
    var stringPassed = ""
    var urlPostPhoto = "http://row52.com/Api/V1/Vehicle/PostPhoto"
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gallery"
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        
        tableView.estimatedRowHeight = 50
        
    }
    /*
     Loads of the cars again when the table is called again
     */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let AppDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        let managedContext = AppDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CarInfo")
        
        do{
            listOfCars = try managedContext.fetch(fetchRequest)
            
            for list in listOfCars{
                print(list.value(forKey: "barcode")!)
                print(list.value(forKey: "pathtofile")!)
                print("************")
            }
            
            
        }catch let error as NSError{
            print(error.userInfo)
        }
        self.tableView.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return listOfCars.count
    }
    
    
    @IBAction func UploadAllPhotos(_ sender: Any) {
        // adding activity indicator
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray

        
        // ignores all the events while the application is running
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
        DispatchQueue.global(qos: .background).async {
            self.UploadRequestwithAlamofire()
            
            DispatchQueue.main.async {
                self.view.addSubview(self.activityIndicator)
                self.activityIndicator.startAnimating()
                
            }
        }
        
    }
    
    
    /*
     Renders the tableView with the photo of the car and the barCode
     Reads all the information from the coreData database
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttractionTableCell", for: indexPath) as! AttractionTableViewCell
        // change the height for the row
        self.tableView?.rowHeight = 88.0
        //let row = indexPath.row
        
        let oneCar = listOfCars[indexPath.row]
        
        // all the rendering is going to happen here
        cell.attractionLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        
        cell.attractionLabel.text = oneCar.value(forKey: "barcode") as? String
        let pathToFile = oneCar.value(forKey: "pathtofile") as! String
        
        if FileManager.default.fileExists(atPath: pathToFile){
            //let url = NSURL(string: pathToFile)
            //let data = NSData(contentsOf: url as! URL)
            
            cell.attractionImage.image = UIImage(named: pathToFile)
        }
        else{
            print("File doesn't excits")
        }
        
        return cell
    }
    
    /*
     Deletes a single cell in the TableView when you swipe right
     */
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete{
            
            // gets one car from the array listOfCars in memory
            let oneCar = listOfCars[indexPath.row]
            
            // gets the barCode for that specific car
            let barCodeFromCar = oneCar.value(forKey: "barcode") as? String
            
            // deletes car from DB based on the barCode
            let deleteSuccessful = deleteBarcode(withId: barCodeFromCar!)
            
            // if the deletion is successful
            // removes car from the array of listOfCars in memory
            // deletes the car from the TableView
            if deleteSuccessful == true {
                listOfCars.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            else{
                print("Unable to delete car from DB \(barCodeFromCar!)")
            }
        }
    }
    
    /*
     Deletes a single entry from the local database based	 on the barCode
     */
    
    func deleteBarcode(withId: String) -> Bool{
        
        let moc = getContext()
        let fetchRequest: NSFetchRequest<CarInfo> = CarInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(barcode = %@)", withId)
        if let result = try? moc.fetch(fetchRequest){
            for object in result{
                moc.delete(object)
            }
            do{
                try moc.save()
            }catch let error as NSError{
                print("Could not save")
            }catch{
                
            }
            return true
        }
        return false
    }
    
    func getContext () -> NSManagedObjectContext{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    /*
     First Step
     - get url to post photos
     - get token
     - import method upload
     
     Second Step
     - get array of cars in memory
     - loop through the size
     - get element at I
     - Upload file
     - Delete element from DB
     - Delete from array in memory
     
     Third Step
     - Reload TableView
     - Add progress bar while loading the files
     
     */
    
    func UploadRequestwithAlamofire(){
        // add activity indicator
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
        
        // get barCode and Image from Array in memory
        
        for car in listOfCars{
            
            stringPassed = car.value(forKey: "barcode") as! String
            let pathToFile = car.value(forKey: "pathtofile") as! String
            
            if !FileManager.default.fileExists(atPath: pathToFile){
                print("No file in the upload method")
                return
            }
            
            
            let urlPostPhoto = self.urlPostPhoto + "?" + "barcode=" + stringPassed
            let tempImage = UIImage(named: pathToFile)
            
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
                        // deletes car from DB based on the barCode
                        let deleteSuccessful = self.deleteBarcode(withId: self.stringPassed)
                        
                        // if the deletion is successful
                        // removes car from the array of listOfCars in memory
                        // deletes the car from the TableView
                        if deleteSuccessful == true {
                            let indexOfCar = self.listOfCars.index(of: car)
                            self.listOfCars.remove(at: indexOfCar!)
                            
                            let indexPath = NSIndexPath(row: indexOfCar!, section: 0)
                            
                            self.tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
                        }
                        else{
                            print("Unable to delete barcode from DB \(self.stringPassed)")
                        }
                        
                        
                        print(response.response)
                        print(response.data)
                        print(response.result)
                        
                        if let JSON = response.result.value {
                            print("JSON: \(JSON)")
                        }
                    }
                case .failure( let encodingError):
                    print("Printing error here ******\(encodingError)")
                }
            }
        }
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
