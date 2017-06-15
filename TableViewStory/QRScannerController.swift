//
//  QRController
//  QRScannerController.swift
//  QRCodeReader
//
//

import UIKit
import AVFoundation
import CoreData

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    let alert = UIAlertView()
    
    let managedObjectContext =  (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // second part -- incorporating camera features
    /**** clean this code -remove ***/////
    var imagePicker: UIImagePickerController!
    var imagesDirectoyPath: String!
    var images: [UIImage]!
    var titles: [String]!
    var newDir: String!
    
    
    // supports different type of barCodes
    let supportedCodeTypes = [AVMetadataObjectTypeUPCECode,
                              AVMetadataObjectTypeCode39Code,
                              AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeCode93Code,
                              AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypeEAN8Code,
                              AVMetadataObjectTypeEAN13Code,
                              AVMetadataObjectTypeAztecCode,
                              AVMetadataObjectTypePDF417Code,
                              AVMetadataObjectTypeQRCode]
    
    
    //@IBOutlet var messageLabel:UILabel!
    //@IBOutlet var topbar: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        

        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // need to specify which type of code to scan. In this case the type is QR
        
            //******************//
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            
            // Start video capture.
            captureSession?.startRunning()
            
            
            // Move the message label and top bar to the front
            //view.bringSubview(toFront: messageLabel)
            //view.bringSubview(toFront: topbar)
            
        
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
   
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
           // messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code met a data then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
               // messageLabel.text = metadataObj.stringValue
               // fire the camera to get the photo
               
                // Calling camera -- move it to the cameraController
                //launchCamera()
                
                
                //alert.title = "BarCode"
                //alert.message = metadataObj.stringValue
                // metadataObj.stringValue is the the result with the barCode
                
               
//                let myVC = storyboard?.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
//                myVC.stringPassed = metadataObj.stringValue!
//                navigationController?.pushViewController(myVC, animated: true)
                print("Printing metadata")
                self.captureSession?.stopRunning()
                //**********///
                // check the line before to dismiss the view
                self.dismiss(animated: true, completion: {})
                print(metadataObj.stringValue)
                let userInput = metadataObj.stringValue!
                
                /*
                        Here is the logic
                            - get barCode
                            - check local db if barCode in db
                                        display alert
                                    else
                                        segue to the next view
                    */
                
                let checkFileInLocalDb = checkLocalDb(barCode: userInput)
                
                if checkFileInLocalDb == false{
                   performSegue(withIdentifier: "goToSecondVC", sender: userInput)
                }
                else{
                    
                    let alertController = UIAlertController(title:"Barcode", message: "File already exists in the gallery", preferredStyle: UIAlertControllerStyle.alert)
                    
                    let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
                    {
                        (result: UIAlertAction) -> Void in
                        print("You pressed OK")
                    }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    self.viewDidLoad()
                    //alert.addButton(withTitle: "File already exists in the gallery")
                    //alert.show()
                }
                
            }
        }
    }
    
    func checkLocalDb (barCode: String) -> Bool{
        if barCode == ""{
            return false
        }
        else{
            let entityDescription = NSEntityDescription.entity(forEntityName: "CarInfo", in: managedObjectContext)
            let request: NSFetchRequest<CarInfo> = CarInfo.fetchRequest()
            request.entity = entityDescription
            
            let pred = NSPredicate(format: "(barcode = %@)", barCode)
            request.predicate = pred
            
            do{
                let results = try managedObjectContext.fetch(request as! NSFetchRequest<NSFetchRequestResult>)
                
                if results.count > 0{
                    return true
                }
                
            }catch let error{
                print(error.localizedDescription)
            }
        }
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession?.startRunning();
        }
    }
    
    // Review the methods below
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession?.stopRunning();
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "goToSecondVC"{
            let nextScene = segue.destination as! CameraViewController
            let backItem = UIBarButtonItem()
            backItem.title = "Scan Again"
            navigationItem.backBarButtonItem = backItem
            nextScene.stringPassed = sender as! String
        }
    }
//
//    Another way of passing data to the next ViewController
//    func showNextController(){
//        let destination = secondController(nibName: "CameraViewController", Bundle: NSBundle.mainBundle())
//            destination.passedString = self.myInformation
//        self.showViewController(destination, sender: self)
//    }
//    
    
//    func launchCamera(){
//        // creates an object of type UIImagePikcerController and and set the type to camera
//        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
//            
//            let imagePicker = UIImagePickerController()
//            
//            imagePicker.delegate = self
//            imagePicker.sourceType = .camera
//            
//            self.present(imagePicker, animated: true, completion: nil)
//        }
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        self.dismiss(animated: true, completion: nil)
//    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}












