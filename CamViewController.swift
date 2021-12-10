//
//  CamViewController.swift
//  DataEntries
//
//  Created by Gabani M1 on 08/12/21.
//

import UIKit
import MobileCoreServices
import AVFoundation
import SDWebImage
import Alamofire

class CamViewController: UIViewController,UIImagePickerControllerDelegate & UINavigationControllerDelegate,AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet var cameraView: UIView!
    @IBOutlet weak var lblTimCount: UILabel!
    
    var selectedImage = UIImage()
    var imagePicker = UIImagePickerController()
    var captureSession = AVCaptureSession()
    var sessionOutput = AVCaptureStillImageOutput()
    var movieOutput = AVCaptureMovieFileOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    var VideoURL = NSURL()
    var imgThumbnail = UIImageView()
    
    var count = 0
    var resendTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
        //  self.cameraView = self.view
        
        let session = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        let devices = session.devices
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
        for device in devices
        {
            if device.position == AVCaptureDevice.Position.back
            {
                do{
                    let input = try AVCaptureDeviceInput(device: device )
                    let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                    if captureSession.canAddInput(input){
                        
                        captureSession.addInput(input)
                        captureSession.addInput(audioDeviceInput)
                        sessionOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecType.jpeg]
                        
                        if captureSession.canAddOutput(sessionOutput)
                        {
                            captureSession.addOutput(sessionOutput)
                            
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                            previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                            cameraView.layer.addSublayer(previewLayer)
                            previewLayer.position = CGPoint(x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
                            previewLayer.bounds = cameraView.frame
                            
                        }
                        captureSession.addOutput(movieOutput)
                        captureSession.startRunning()
                    }
                }
                catch{
                    
                    print("Error")
                }
            }
        }
    }
    @objc func update() {
        
        count = count + 1
        
        if count < 10
        {
            lblTimCount.text = "00 : 0\(count)"
        }
        else
        {
            lblTimCount.text = "00 : \(count)"
        }
    }
    
    func handleCaptureSession()
    {
        resendTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        print("-----------Starting-----------")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        let fileName = dateString + "output.mov"
        let fileUrl = paths[0].appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileUrl)
        self.movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute:{
            print("-----------Stopping-----------")
            self.movieOutput.stopRecording()
        })
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("FINISHED \(error )")
        // save video to camera roll
        if error == nil {
            print("---------------FilePath--------------\(outputFileURL.path)")
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
            resendTimer.invalidate()
            
            VideoURL = (outputFileURL as? NSURL)!
            lblTimCount.text = "00 : 00"
            count = 0
            
            imgThumbnail.image = thumbnailForVideoAtURL(url: outputFileURL as NSURL)
            
            uploadVideo()
            
            let alert = UIAlertController(title: "Successfully !!", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func cameraButton(_ sender: Any) {
        self.handleCaptureSession()
    }
    
    private func thumbnailForVideoAtURL(url: NSURL) -> UIImage? {
        
        let asset = AVAsset(url: url as URL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }
    }
    
    func uploadVideo() {
        
        let param = ["userName": "Dummy1","userCountry": "es","userPicture": "http://air.flaxbin.com/profiles/guest.png"] as [String : Any]
        
        APIClient.sharedInstance.showIndicator()
        
        postVideoToServer(THU_VIDEO, videoURL: VideoURL as? URL, parameters: param){ (response, error, statusCode) in
            print("Response \(String(describing: response))")
            print("STATUS CODE \(String(describing: statusCode))")
            
            APIClient.sharedInstance.hideIndicator()

            if error == nil {
                
                if statusCode == 200
                {
                    
    
                }
                else
                {
    
                }
                
            }
            else{
               
                
            }
        }
    }
    
    func postVideoToServer(_ url: String, videoURL: URL!, parameters: [String: Any], completionHandler:@escaping (NSDictionary?, Error?, Int?) -> Void) {
        
        let imageData = self.imgThumbnail.image!.jpegData(compressionQuality: 0.1)
        let finalUrl = BASE_URL + url
        print("Requesting \(finalUrl)")
        print("Parameters: \(parameters)")
        print("videoURL :\(videoURL)")
        
        //        let imageData = UIImageJPEGRepresentation(UIImage(named: "")!, 0.1)
        
        let authToken = UserDefaults.standard.value(forKey: "user_token") as? String ?? ""
        let authorizationStr = "Bearer " + authToken
        
        if (videoURL != nil)
        {
            
            let headers: HTTPHeaders = [
            ]
            
            AF.upload(multipartFormData: { multiPart in
                for p in parameters {
                    multiPart.append("\(p.value)".data(using: String.Encoding.utf8)!, withName: p.key)
                }
                multiPart.append(videoURL, withName: "video", fileName: "video.mp4", mimeType: "video/mp4")
                multiPart.append(imageData!, withName: "thumbnail", fileName: "photo.jpg", mimeType: "image/jpeg")

            }, to: url, method: .post, headers: headers) .uploadProgress(queue: .main, closure: { progress in
                print("Upload Progress: \(progress.fractionCompleted)")
            }).responseJSON(completionHandler: { data in
                print("upload finished: \(data)")
                
                let responseDict = ((data.value as AnyObject) as? NSDictionary)
                print(responseDict)
                
                if let responseDict = ((data.value as AnyObject) as? NSDictionary)
                {
                    completionHandler(responseDict, nil, data.response?.statusCode)
                }
                
            }).response { (response) in
                switch response.result {
                case .success(let resut):
                    print("upload success result: \(resut)")

                    if let err = response.error{
                        completionHandler(nil, err, response.response?.statusCode)

                        return
                    }
                    if let responseDict = ((response.value as AnyObject) as? NSDictionary)
                    {
                        completionHandler(responseDict, nil, response.response?.statusCode)
                    }
                    
                case .failure(let err):
                    print("upload err: \(err)")
                }
            }
           
        }
    }
    
    
}


/*@IBAction func openCameraButton(_ sender: Any) {
 if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
 if UIImagePickerController.availableCaptureModes(for: .rear) != nil {
 imagePicker.sourceType = .camera
 imagePicker.mediaTypes = [kUTTypeMovie as String]
 imagePicker.allowsEditing = false
 imagePicker.delegate = self
 present(imagePicker, animated: true, completion: {})
 } else {
 //  postAlert("Rear camera doesn't exist", message: "Application cannot access the camera.")
 }
 } else {
 // postAlert("Camera inaccessible", message: "Application cannot access the camera.")
 }
 
 //   openCamera()
 }
 
 @objc func startRecording() {
 
 }
 
 @IBAction func openLibraryButton(_ sender: Any) {
 openGallary()
 }
 
 // MARK: - Camera & Photo Picker
 func openCamera()
 {
 if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
 {
 imagePicker.sourceType = UIImagePickerController.SourceType.camera
 imagePicker.allowsEditing = true
 imagePicker.mediaTypes = [kUTTypeImage as String]
 self.present(imagePicker, animated: true, completion: nil)
 }
 else
 {
 AppUtilites.showAlert(title: "", message: "You don't have camera", cancelButtonTitle: "OK")
 }
 }
 
 func openGallary()
 {
 imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
 imagePicker.allowsEditing = true
 imagePicker.mediaTypes = ["public.image"]
 self.present(imagePicker, animated: true, completion: nil)
 }
 
 func imagePickerController(_ picker: UIImagePickerController,
 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
 
 
 if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
 imgView.image = image
 selectedImage = image
 }
 else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
 imgView.image = image
 selectedImage = image
 }
 
 picker.dismiss(animated: true, completion: nil)
 }
 
 @IBAction func saveButton(_ sender: Any) {
 let imageData = selectedImage.jpegData(compressionQuality: 0.6)
 let compressedJPGImage = UIImage(data: imageData!)
 UIImageWriteToSavedPhotosAlbum(compressedJPGImage!, nil, nil, nil)
 }*/
