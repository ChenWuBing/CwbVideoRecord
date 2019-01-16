
import UIKit

enum CWBAlertViewStyle {
    case actionSheet
    case alert
}
//MARK:可根据自己项目需求添加功能
///默认按钮颜色
let defaultColor = UIColor.init(red: 0, green: 128/255, blue: 1, alpha: 1)
///自定义可以用UIView.Show()显示出来效果的弹窗
class CWBAlertView: UIButton {
    ///中间视图
    fileprivate var centerView = UIView()
    ///标题
    fileprivate var title:String?
    ///标题字体颜色
    var titleColor = UIColor.black
    ///标题字体大小
    var titleFont:CGFloat = 15.0
    ///提示信息
    fileprivate var message:String?
    ///提示信息字体颜色
    var messageColor = UIColor.init(red: 65/255, green: 65/255, blue: 65/255, alpha: 1)
    ///提示信息字体大小
    var messageFont:CGFloat = 14.0
    ///弹窗类型
    fileprivate var type:CWBAlertViewStyle!
    ///按钮个数
    fileprivate var actionArray = [CWBAlertAction]()
    ///是否可以点击消失
    fileprivate var canClickDismis = true
    
    ///开始点击时间
    fileprivate var beganTimer:TimeInterval = 0
    
    deinit {
        print("销毁自定制弹窗")
    }
    public convenience init(title: String?, message: String?, preferredStyle: CWBAlertViewStyle) {
        
        self.init()
        for sView in UIApplication.shared.delegate!.window!!.subviews {
            if sView.isKind(of: CWBAlertView.classForCoder())  {
                let alertView = sView as! CWBAlertView
                if alertView.message == message {
                    return
                }
            }
        }
        self.title = title
        self.message = message
        self.type = preferredStyle
        self.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.layoutIfNeeded()
    }
    open func addAction(_ action: CWBAlertAction) {
        actionArray.append(action)
    }
    open func show(){
        UIView.animate(withDuration: 0.3) {
//            self.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        }
        let centerViewWidth = self.type == CWBAlertViewStyle.alert ? self.frame.size.width * 0.75 : self.frame.size.width * 0.9
        var titleHeight:CGFloat = 0
        var messageHeight:CGFloat = 0
        var actionHeight:CGFloat = 0
        var y:CGFloat = 15
        self.centerView.layer.masksToBounds = true
        self.centerView.layer.cornerRadius = 8
        self.centerView.backgroundColor = UIColor.white
        
        if self.title != nil {
            titleHeight = self.calculateStringSize(str: self.title!, maW: centerViewWidth - 10, maH: 10000, fontSize: self.titleFont).height
            //标题
            let titleLabel = UILabel.init(frame: CGRect.init(x: 5, y: 15, width: centerViewWidth - 10, height: titleHeight))
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.font = UIFont.boldSystemFont(ofSize: self.titleFont)
            titleLabel.text = self.title!
            titleLabel.textColor = self.titleColor
            self.centerView.addSubview(titleLabel)
        }
        if self.message != nil {
            //提示语
            messageHeight = self.calculateStringSize(str: self.message!, maW: centerViewWidth - 30, maH: 10000, fontSize: self.messageFont).height
            let messageLabel = UILabel.init(frame: CGRect.init(x: 15, y: titleHeight != 0 ? titleHeight + 25 : 15, width: centerViewWidth - 30, height: messageHeight))
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            messageLabel.text = self.message!
            messageLabel.font = UIFont.systemFont(ofSize: self.messageFont)
            messageLabel.textColor = self.messageColor
            self.centerView.addSubview(messageLabel)
        }
        
        if titleHeight != 0{
            y += titleHeight + 15
        }
        if messageHeight != 0{
            y += messageHeight + 15
        }
        
        if self.type == CWBAlertViewStyle.alert {
            if self.actionArray.count == 1 {
                if y != 15 {
                    let lineView1 = UIView.init(frame: CGRect.init(x: 0, y: y, width: centerViewWidth, height: 0.5))
                    lineView1.backgroundColor = UIColor.init(red: 180/255, green: 180/255, blue: 180/255, alpha: 1)
                    self.centerView.addSubview(lineView1)
                }
                
                let action = self.actionArray.first
                action?.frame = CGRect.init(x: 0, y: y, width: centerViewWidth, height: 40)
                actionHeight += 40.5
                self.centerView.addSubview(action!)
            }
            else if self.actionArray.count == 2 {
                if y != 15 {
                    let lineView1 = UIView.init(frame: CGRect.init(x: 0, y: y, width: centerViewWidth, height: 0.5))
                    lineView1.backgroundColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
                    self.centerView.addSubview(lineView1)
                }
                let action1 = self.actionArray.first
                action1?.frame = CGRect.init(x: 0, y: y, width: centerViewWidth * 0.5 - 0.5, height: 40)
                self.centerView.addSubview(action1!)
                
                let lineView2 = UIView.init(frame: CGRect.init(x: centerViewWidth * 0.5, y: y, width: 0.5, height: 40))
                lineView2.backgroundColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
                self.centerView.addSubview(lineView2)
                
                let action2 = self.actionArray.last
                action2?.frame = CGRect.init(x: centerViewWidth * 0.5, y: y, width: centerViewWidth * 0.5 + 0.5, height: 40)
                self.centerView.addSubview(action2!)
                actionHeight += 40.5
            }
            else {
                for (index,action) in self.actionArray.enumerated() {
                    let lineView = UIView.init(frame: CGRect.init(x: 0, y: y + CGFloat(index * 40), width: centerViewWidth, height: 0.5))
                    lineView.backgroundColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
                    self.centerView.addSubview(lineView)
                    action.frame = CGRect.init(x: 0, y: y + CGFloat(index * 40) + 0.5, width: centerViewWidth, height: 40)
                    self.centerView.addSubview(action)
                    actionHeight += 40.5
                }
            }
        }
        else{
            if titleHeight == 0 && messageHeight == 0 {
                y = 0
            }
            for (index,action) in self.actionArray.enumerated() {
                if index != 0 || y != 0{
                    let lineView = UIView.init(frame: CGRect.init(x: 0, y: y + CGFloat(index * 40), width: centerViewWidth, height: 0.5))
                    lineView.backgroundColor = UIColor.init(red: 180/255, green: 180/255, blue: 180/255, alpha: 1)
                    self.centerView.addSubview(lineView)
                }
                action.frame = CGRect.init(x: 0, y: y + CGFloat(index * 40) + 0.5, width: centerViewWidth, height: 40)
                self.centerView.addSubview(action)
                actionHeight += 40.5
            }
        }
        
        let totalH = y + actionHeight
        if totalH > UIScreen.main.bounds.height {
            //添加中心视图
            self.centerView.frame = CGRect.init(x: 0, y: 0, width: centerViewWidth, height: UIScreen.main.bounds.height - 40)
            self.centerView.center = self.center
            self.centerView.alpha = 0.5
            for view in self.centerView.subviews {
                view.removeFromSuperview()
            }
            let textView = UITextView.init(frame: self.centerView.bounds)
            textView.text = message
            textView.isScrollEnabled = true
            textView.isEditable = false
            textView.font = UIFont.systemFont(ofSize: self.messageFont)
            self.centerView.addSubview(textView)
            self.addSubview(self.centerView)
            UIView.animate(withDuration: 0.3) {
                self.centerView.alpha = 1
            }
        }
        else {
            if self.type == CWBAlertViewStyle.alert {
                //添加中心视图
                self.centerView.frame = CGRect.init(x: 0, y: 0, width: centerViewWidth, height: totalH)
                self.centerView.center = self.center
                self.centerView.alpha = 0.5
                self.addSubview(self.centerView)
                UIView.animate(withDuration: 0.3) {
                    self.centerView.alpha = 1
                }
            }
            else{
                //添加底部视图
                self.centerView.frame = CGRect.init(x: 0, y: 0, width: centerViewWidth, height: totalH)
                self.centerView.center = CGPoint.init(x: self.center.x, y: self.frame.size.height + (totalH) * 0.5)
                self.addSubview(self.centerView)
                UIView.animate(withDuration: 0.3) {
                    self.centerView.center = CGPoint.init(x: self.center.x, y: self.frame.size.height - (totalH + 20) * 0.5)
                }
            }
        }
        ///毛玻璃效果
        let effect = UIBlurEffect.init(style: .dark)
        let effectView = UIVisualEffectView.init(effect: effect)
        effectView.frame = self.bounds
        effectView.alpha = 0.55
        self.addSubview(effectView)
        self.sendSubviewToBack(effectView)
        
        UIApplication.shared.delegate?.window!!.addSubview(self)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.beganTimer = Date().timeIntervalSince1970
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if canClickDismis && (touches.first?.view)! != self.centerView && !(touches.first?.view)!.isKind(of: CWBAlertAction.classForCoder()){
            let dic = Date().timeIntervalSince1970 - self.beganTimer
            if dic < 0.5 {
                if self.type == CWBAlertViewStyle.alert {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.alpha = 0.5
                    }) { (_) in
                        self.removeFromSuperview()
                    }
                }
                else{
                    UIView.animate(withDuration: 0.3, animations: {
                        self.centerView.center = CGPoint.init(x: self.center.x, y: self.frame.size.height + self.centerView.frame.size.height * 0.5)
                    }) { (_) in
                        self.removeFromSuperview()
                    }
                }
            }
        }
        self.beganTimer = 0
    }
    ///计算字符串大小
    fileprivate func calculateStringSize(str: String, maW: CGFloat, maH: CGFloat, fontSize: CGFloat) -> CGSize {
        
        let paragraohStyle = NSMutableParagraphStyle()
        paragraohStyle.lineSpacing = 1
        let dict = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize), NSAttributedString.Key.paragraphStyle: paragraohStyle]
        let nsStr = str as NSString
        return nsStr.boundingRect(with: CGSize.init(width: maW, height: maH), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: dict, context: nil).size
        
    }
}

enum CWBAlertActionStyle : Int {
    case `default`
    case cancel
}
class CWBAlertAction : UIButton{
    //标题
    var title:String?
    //事件
    fileprivate var handler:((CWBAlertAction) -> Swift.Void)?
    //文字颜色
    var textColor:UIColor?{
        didSet {
            self.layoutSubviews()
        }
    }
    //文字大小
    var textFont:CGFloat?{
        didSet {
            self.layoutSubviews()
        }
    }
    //类型
    private var style:CWBAlertActionStyle?
    
    public convenience init(title: String?, style: CWBAlertActionStyle, handler: ((CWBAlertAction) -> Void)? = nil) {
        self.init()
        self.layoutIfNeeded()
        self.title = title
        self.handler = handler
        self.addTarget(self, action: #selector(touchesHandler), for: .touchUpInside)
        self.style = style
    }
    override func layoutSubviews() {
        if self.title != nil {
            let titleLabel = UILabel.init(frame: self.bounds)
            if self.style != nil {
                if self.style! == CWBAlertActionStyle.cancel {
                    titleLabel.textColor = UIColor.init(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)
                }
                else{
                    titleLabel.textColor = textColor != nil ? textColor! : defaultColor
                }
            }
            else{
                titleLabel.textColor = textColor != nil ? textColor! : defaultColor
            }
            
            titleLabel.textAlignment = .center
            titleLabel.text = self.title!
            titleLabel.font = self.textFont == nil ? UIFont.systemFont(ofSize:  16.0) : UIFont.systemFont(ofSize:  self.textFont!)
            self.addSubview(titleLabel)
        }
    }
    @objc fileprivate func touchesHandler(){
        if handler != nil {
            handler!(self)
        }
        self.disMissCenterView()
    }
    fileprivate func disMissCenterView(){
        if let fView = self.superview?.superview as? CWBAlertView {
            if fView.type == CWBAlertViewStyle.alert {
                UIView.animate(withDuration: 0.3, animations: {
                    fView.alpha = 0.5
                }) { (_) in
                    fView.removeFromSuperview()
                }
            }
            else{
                UIView.animate(withDuration: 0.3, animations: {
                    fView.centerView.center = CGPoint.init(x: fView.center.x, y: fView.frame.size.height + fView.centerView.frame.size.height * 0.5)
                }) { (_) in
                    fView.removeFromSuperview()
                }
            }
        }
    }
}
