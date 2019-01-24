
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        self.privacyPermission(type: PrivacyPermissionType.camera)
    }
    //权限检测
    fileprivate func privacyPermission(type:PrivacyPermissionType) {
        PrivacyPermission.sharedInstance().accessPrivacyPermission(with: type) { (bol, status) in
            if !bol {
                self.openSystemView()
            }
            else{
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    DispatchQueue.main.async {
                        if type == PrivacyPermissionType.camera {
                            self.privacyPermission(type: PrivacyPermissionType.microphone)
                        }
                        else if type == PrivacyPermissionType.microphone {
                            self.privacyPermission(type: PrivacyPermissionType.photo)
                        }
                        else if type == PrivacyPermissionType.photo {
                            self.present(CwbVideoRecordVC(), animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    ///打开App系统权限界面
    fileprivate func openSystemView(){
        if #available(iOS 10.0, *) {
            DispatchQueue.main.async {
                UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
        else {
            DispatchQueue.main.async {
                UIApplication.shared.openURL(URL.init(string: UIApplication.openSettingsURLString)!)
            }
        }
    }
}

