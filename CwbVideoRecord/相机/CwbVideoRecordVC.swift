/*
 崩溃：Tried to overrelease a framebuffer, did you forget to call -useNextFrameForImageCapture before using -imageFromCurrentFramebuffer?
 
 是因为 framebufferReferenceCount的值小于0，这里是GPUImage对buffer的缓存处理，简单的解决办法是在
 
 GPUImageFramebuffer.m中unlock方法添加一个判断
 
 if (framebufferReferenceCount <1) {
 
 return;
 
 }

 */

import UIKit
import GPUImage
import AssetsLibrary
import Photos

class CwbVideoRecordVC: UIViewController{
    //MARK:属性
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var picButton: UIButton!
    @IBOutlet weak var botView: UIView!
    @IBOutlet weak var SwitchButton: UIButton!
    @IBOutlet weak var CloseButton: UIButton!
    @IBOutlet weak var lightButton: UIButton!
    @IBOutlet weak var startRecordButton: UIButton!
    ///水印背景框
    @IBOutlet weak var waterView: UIView!
    
    ///视频拍摄
    fileprivate var MyCamera:GPUImageStillCamera?
    ///取景框
    fileprivate var myGPUImageView:GPUImageView?
    ///滤镜文件
    fileprivate var filter:GPUImageFilter?
    ///滤镜
    fileprivate var ljFilter:GPUImageOutput?
    ///视频输出
    fileprivate var movieWriter:GPUImageMovieWriter?
    ///开始的缩放比例
    fileprivate var beginGestureScale:CGFloat = 1.0
    ///最后的缩放比例
    fileprivate var effectiveScale:CGFloat = 1.0
    ///最大放大倍数
    fileprivate let maxScaleAndCropFactor:CGFloat = 5.0
    ///是否打开闪光灯
    fileprivate var isOpenLight = false
    ///是否开始录制
    fileprivate var isCamera = false
    ///判断前置还是后置
    fileprivate var isFontCamera = false
    ///录制还是拍照
    fileprivate var isTakeVideo = true
    ///录制计时器
    fileprivate var videoTimer:Timer?
    ///视频最长时间(s)
    fileprivate var videoMaxTime = 0
    ///视频录制时间(s)
    fileprivate var videoTime = 0
    ///路是时间计时器
    fileprivate var Timer:Timer?
    ///水印图片数组
    fileprivate var cameraImgArr = [UIImage]()
    ///视频URL地址
    fileprivate lazy var videoUrl:URL = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first!
        let str = documentsDirectory + "/myMov.mp4"
        let myPathDocs = str as NSString
        unlink(myPathDocs.utf8String)
        return URL.init(fileURLWithPath: myPathDocs as String)
    }()
    ///聚焦层
    fileprivate var focusLayer:CALayer?
    ///纹理图片
    fileprivate var pictureFile:GPUImagePicture?
    ///时间水印
    fileprivate var timeLabel:UILabel?
    //MARK:程序生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        self.waterView.backgroundColor = UIColor.white.withAlphaComponent(0)
        self.cameraImgArr = [UIImage.init(named: "video_startRecord")!,UIImage.init(named: "video_force_Img")!]
        self.videoButton.setTitleColor(UIColor.white, for: .normal)
        self.timeLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 30))
        self.timeLabel?.textColor = UIColor.white
        self.timeLabel?.font = UIFont.systemFont(ofSize: 15)
        self.timeLabel?.textAlignment = .center
        self.waterView.addSubview(self.timeLabel!)
        self.waterView.bringSubviewToFront(self.timeLabel!)
        self.picButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        self.botView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.botView.layer.masksToBounds = true
        self.botView.layer.cornerRadius = 4
        self.setCamera(device: AVCaptureDevice.Position.back)
        ///设置聚焦层
        let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 80, height: 80))
        imageView.image = UIImage.init(named: "video_force_Img")
        self.focusLayer = imageView.layer
        self.focusLayer?.isHidden = true
        self.view.layer.addSublayer(self.focusLayer!)
        ///添加点击手势
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(focus))
        self.view.addGestureRecognizer(tap)
        ///设置调焦距
        let pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(focusDisdance))
        pinch.delegate = self
        self.view.addGestureRecognizer(pinch)
    }
    //MARK:设置相机
    fileprivate func setCamera(device:AVCaptureDevice.Position){
        self.MyCamera = GPUImageStillCamera.init(sessionPreset: AVCaptureSession.Preset.hd1280x720.rawValue, cameraPosition: device)
        self.MyCamera?.outputImageOrientation = .portrait
        self.MyCamera?.horizontallyMirrorRearFacingCamera = false
        self.MyCamera?.horizontallyMirrorFrontFacingCamera = false
        
        //该句可防止允许声音通过的情况下，避免录制第一帧黑屏闪屏
        self.MyCamera?.addAudioInputsAndOutputs()
        
        //滤镜view
        self.myGPUImageView = GPUImageView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        DispatchQueue.main.async {
            self.myGPUImageView?.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        }
        self.MyCamera?.addTarget(self.myGPUImageView!)
        self.view.addSubview(self.myGPUImageView!)
        self.view.sendSubviewToBack(self.myGPUImageView!)
        //滤镜文件设置
        self.filter = GPUImageMultiplyBlendFilter.init()
        self.MyCamera?.addTarget(self.filter!)
        //MARK:水印纹理设置
        self.pictureFile = GPUImagePicture.init(image: self.screenSnapshot(view: self.waterView)!)
        self.pictureFile?.addTarget(self.filter!)
        self.pictureFile?.useNextFrameForImageCapture()
        self.pictureFile?.processImage()
        
        //视频写入文件
        self.movieWriter = GPUImageMovieWriter.init(movieURL: self.videoUrl, size: CGSize.init(width: 920, height: 1680))
        self.movieWriter?.encodingLiveVideo = true
        self.movieWriter?.shouldPassthroughAudio = true
        self.movieWriter?.hasAudioTrack = true
        self.filter?.addTarget(self.movieWriter!)
        self.MyCamera?.audioEncodingTarget = self.movieWriter!
        self.MyCamera?.delegate = self
        self.MyCamera?.startCapture()
        
    }
    deinit {
        self.Timer?.invalidate()
        self.Timer = nil
        print("销毁 - 定制相机")
    }
    //MARK:设置水印试图位置
    func setWaterViewInRect(waterView:UIView,rect:CGRect){
        let vi = UIView.init(frame: rect)
        vi.addSubview(waterView)
        self.waterView.addSubview(vi)
    }
    ///开始录制
    @IBAction func StartRecordAction(_ sender: UIButton) {
        if self.isTakeVideo {
            ///开始录制
            if !self.isCamera {
                self.timeLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                let dateF = DateFormatter.init()
                dateF.dateFormat = "yyyy-MM-dd HH:mm:ss"
                self.timeLabel?.text = dateF.string(from: Date())
                self.Timer = WeakTimerObject.scheduledTimerWithTimeInterval(interval: 1, aTargat: self, aSelector: #selector(timerAction), userInfo: nil, repeats: true)
                self.startRecordButton.setTitle("0", for: .normal)
                self.movieWriter?.startRecording()
                self.isCamera = true
                self.botView.isHidden = true
                sender.setBackgroundImage(UIImage.init(named: "video_endRecord"), for: .normal)
            }
            else{
                self.videoTime = 0
                self.timeLabel?.text = ""
                self.timeLabel?.backgroundColor = UIColor.clear
                self.movieWriter?.finishRecording()
                self.isCamera = false
                self.botView.isHidden = false
                sender.setBackgroundImage(UIImage.init(named: "video_startRecord"), for: .normal)
                sender.setTitle("", for: .normal)
                self.saveTo(videoUrl: self.videoUrl, image: nil)
                self.Timer?.invalidate()
                self.Timer = nil
                
            }
            self.CloseButton.isHidden = self.isCamera
            self.SwitchButton.isHidden = self.isCamera
        }
        else{
            //拍照
            self.MyCamera?.capturePhotoAsImageProcessedUp(toFilter: self.filter!, withCompletionHandler: { (image, error) in
                if error == nil {
                    if error == nil && image != nil {
                        self.saveTo(videoUrl: nil, image: image!)
                    }
                }
            })
        }
    }
    ///时间计时器事件
    @objc fileprivate func timerAction(){
        let dateF = DateFormatter.init()
        dateF.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.timeLabel?.text = dateF.string(from: Date())
        self.videoTime += 1
        self.startRecordButton.setTitle("\(self.videoTime)", for: .normal)
        if videoMaxTime > 0 && videoTime > videoMaxTime{
            self.timeLabel?.text = ""
            self.timeLabel?.backgroundColor = UIColor.clear
            self.movieWriter?.finishRecording()
            self.isCamera = false
            self.startRecordButton.setBackgroundImage(UIImage.init(named: "video_startRecord"), for: .normal)
            self.startRecordButton.setTitle("", for: .normal)
            self.saveTo(videoUrl: self.videoUrl, image: nil)
            self.Timer?.invalidate()
            self.Timer = nil
            self.CloseButton.isHidden = self.isCamera
            self.SwitchButton.isHidden = self.isCamera
            self.botView.isHidden = false
        }
    }
    ///视频
    @IBAction func videoButtonAction(_ sender: UIButton) {
        if !self.isCamera {
            self.isTakeVideo = true
            sender.setTitleColor(UIColor.white, for: .normal)
            self.picButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        }
    }
    //照片
    @IBAction func picButtonActoin(_ sender: UIButton) {
        if !self.isCamera {
            self.isTakeVideo = false
            sender.setTitleColor(UIColor.white, for: .normal)
            self.videoButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        }
    }
    //相机反转
    @IBAction func SwitchButtonAction(_ sender: UIButton) {
        isFontCamera = !isFontCamera
        self.MyCamera?.stopCapture()
        self.MyCamera?.removeTarget(self.myGPUImageView!)
        self.myGPUImageView?.removeFromSuperview()
        self.filter?.removeTarget(self.movieWriter!)
        self.MyCamera?.removeTarget(self.filter!)
        self.pictureFile?.removeAllTargets()
        self.beginGestureScale = 1.0
        self.effectiveScale = 1.0
        self.setCamera(device: isFontCamera ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back)
    }
    //灯光开关
    @IBAction func lightButtonAction(_ sender: UIButton) {
        self.isOpenLight = !self.isOpenLight
        try? self.MyCamera?.inputCamera.lockForConfiguration()
        if self.isOpenLight {
            self.MyCamera?.inputCamera.flashMode = AVCaptureDevice.FlashMode.on
            self.MyCamera?.inputCamera.torchMode = AVCaptureDevice.TorchMode.on
            sender.setImage(UIImage.init(named: "video_openLight"), for: .normal)
        }
        else{
            self.MyCamera?.inputCamera.flashMode = AVCaptureDevice.FlashMode.off
            self.MyCamera?.inputCamera.torchMode = AVCaptureDevice.TorchMode.off
            sender.setImage(UIImage.init(named: "video_closeLight"), for: .normal)
        }
        self.MyCamera?.inputCamera.unlockForConfiguration()
    }
    //关闭
    @IBAction func CloseButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    //聚焦事件
    @objc fileprivate func focus(tap:UITapGestureRecognizer){
        //点击位置
        var touchPoint = tap.location(in: self.view)
        self.layerAnimationWithPoint(point: touchPoint)
        
        ///相机聚焦
        if self.MyCamera?.cameraPosition() == AVCaptureDevice.Position.back {
            touchPoint = CGPoint.init(x: touchPoint.y / tap.view!.bounds.size.height, y: 1 - touchPoint.x / tap.view!.bounds.size.width)
        }
        else{
            touchPoint = CGPoint.init(x: touchPoint.y / tap.view!.bounds.size.height, y: touchPoint.x / tap.view!.bounds.size.width)
        }
        
        if self.MyCamera!.inputCamera.isExposurePointOfInterestSupported && self.MyCamera!.inputCamera.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose) {
            
            if ((try? self.MyCamera!.inputCamera.lockForConfiguration()) != nil) {
                self.MyCamera?.inputCamera.exposurePointOfInterest = touchPoint
                self.MyCamera?.inputCamera.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
                
                if self.MyCamera!.inputCamera.isFocusPointOfInterestSupported && self.MyCamera!.inputCamera.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                    self.MyCamera?.inputCamera.focusPointOfInterest = touchPoint
                    self.MyCamera?.inputCamera.focusMode = AVCaptureDevice.FocusMode.autoFocus
                }
                self.MyCamera?.inputCamera.unlockForConfiguration()
            }
        }
    }
    ///对焦动画
    fileprivate func layerAnimationWithPoint(point:CGPoint){
        if self.focusLayer != nil {
            self.view.isUserInteractionEnabled = false
            ///聚焦点聚焦动画设置
            let layer = self.focusLayer!
            layer.isHidden = false
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.position = point
            layer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
            CATransaction.commit()
            let animation = CABasicAnimation.init(keyPath: "transform")
            animation.toValue = NSValue.init(caTransform3D: CATransform3DMakeScale(1.0, 1.0, 1.0))
            animation.delegate = self
            animation.duration = 0.3
            animation.repeatCount = 1
            animation.isRemovedOnCompletion = false
            animation.fillMode = CAMediaTimingFillMode.forwards
            layer.add(animation, forKey: "animation")
        }
    }
    ///调焦事件
    @objc fileprivate func focusDisdance(pinch:UIPinchGestureRecognizer){
        self.effectiveScale = self.beginGestureScale * pinch.scale
        if self.effectiveScale < 1.0 {
            self.effectiveScale = 1.0
        }
        
        if self.effectiveScale > self.maxScaleAndCropFactor {
            self.effectiveScale = self.maxScaleAndCropFactor
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.025)
        if ((try? self.MyCamera!.inputCamera.lockForConfiguration()) != nil) {
            self.MyCamera?.inputCamera.videoZoomFactor = self.effectiveScale
            self.MyCamera?.inputCamera.unlockForConfiguration()
        }
        CATransaction.commit()
    }
}
//MARK:聚焦动画代理
extension CwbVideoRecordVC:CAAnimationDelegate{
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.perform(#selector(focusLayerNormal), with: self, afterDelay: 0.3)
    }
    //focusLayer回到初始化状态
    @objc fileprivate func focusLayerNormal(){
        self.view.isUserInteractionEnabled = true
        self.focusLayer?.isHidden = true
    }
}
//MARK:调焦距代理
extension CwbVideoRecordVC:UIGestureRecognizerDelegate{
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        weak var weakSelf = self
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.classForCoder()) {
            weakSelf?.beginGestureScale = (weakSelf?.effectiveScale)!
        }
        return true
    }
}
//MARK:相机代理
extension CwbVideoRecordVC:GPUImageVideoCameraDelegate{
    func willOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {
        if isCamera {
            DispatchQueue.main.async {
                let image = self.screenSnapshot(view: self.waterView)
                //MARK:水印纹理重制
                ///防止崩溃
                self.pictureFile?.removeAllTargets()
                self.pictureFile?.removeFramebuffer()
                self.pictureFile = GPUImagePicture.init(image: image)
                self.pictureFile?.addTarget(self.filter!)
                self.pictureFile?.useNextFrameForImageCapture()
                self.pictureFile?.processImage()
            }
        }
    }
}
//MARK:工具方法
extension CwbVideoRecordVC {
    //MARK:写入相册
    fileprivate func saveTo(videoUrl:URL?,image:UIImage?){
        PHPhotoLibrary.shared().performChanges({
            if videoUrl != nil {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl!)
            }
            else if image != nil {
                PHAssetChangeRequest.creationRequestForAsset(from: image!)
            }
        }) { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.showAlert("保存成功")
                }
            }
            else {
                self.showAlert("保存失败")
            }
            if videoUrl != nil {
                DispatchQueue.main.async {
                    try? FileManager.default.removeItem(at: self.videoUrl)
                    self.MyCamera?.stopCapture()
                    self.MyCamera?.removeTarget(self.myGPUImageView!)
                    self.myGPUImageView?.removeFromSuperview()
                    self.filter?.removeTarget(self.movieWriter!)
                    self.MyCamera?.removeTarget(self.filter!)
                    self.pictureFile?.removeAllTargets()
                    self.beginGestureScale = 1.0
                    self.effectiveScale = 1.0
                    self.setCamera(device: self.isFontCamera ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back)
                }
            }
        }
    }
    //MARK:显示提示信息
    fileprivate func showAlert(_ msg:String){
        let alertView = CWBAlertView.init(title: "温馨提示", message: msg, preferredStyle: .alert)
        let action1 = CWBAlertAction.init(title: "确定", style: .cancel, handler: nil)
        alertView.addAction(action1)
        alertView.show()
    }
    //MARK:截图
    fileprivate func screenSnapshot(view: UIView) -> UIImage? {
        // 用下面这行而不是UIGraphicsBeginImageContext()，因为前者支持Retina
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
}
//MARK:计时器解强引用
class WeakTimerObject: NSObject {
    weak var targat: AnyObject?
    var selector: Selector?
    var timer: Timer?
    static func scheduledTimerWithTimeInterval(interval: TimeInterval,
                                               aTargat: AnyObject,
                                               aSelector: Selector,
                                               userInfo: AnyObject?,
                                               repeats: Bool) -> Timer {
        let weakObject      = WeakTimerObject()
        weakObject.targat   = aTargat
        weakObject.selector = aSelector
        weakObject.timer    = Timer.scheduledTimer(timeInterval: interval,
                                                   target: weakObject,
                                                   selector: #selector(fire),
                                                   userInfo: userInfo,
                                                   repeats: repeats)
        return weakObject.timer!
    }
    
    @objc func fire(ti: Timer) {
        if let _ = targat {
            targat?.perform(selector)
            //targat?.perform(selector!, withObject: ti.userInfo)
        } else {
            timer?.invalidate()
        }
    }
}
