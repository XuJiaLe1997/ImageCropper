//
//  DRImageCropperViewController.swift
//  LoveTrail
//
//  Created by Xiaoqiang Zhang on 16/3/16.
//  Copyright © 2016年 Xiaoqiang Zhang. All rights reserved.
//

import UIKit

let SCALE_FRAME_Y    = 100.0
let BOUNDCE_DURATION = 0.3

@objc protocol DRImageCropperDelegate : NSObjectProtocol {
    func imageCropper(_ cropperViewController: DRImageCropperViewController, editImg: UIImage)
    
    func imageCropperDidCancel(_ cropperViewController: DRImageCropperViewController)
}

class DRImageCropperViewController: UIViewController  {
    
    var originalImage: UIImage?
    var editedImage: UIImage?
    
    var showImgView: UIImageView?
    var overlayView: UIView?
    var ratioView: UIView?
    
    var oldFrame: CGRect?
    var largeFrame: CGRect?
    var limitRatio: CGFloat?
    
    var latestFrame: CGRect?
    var cropFrame: CGRect?
    
    var delegate: DRImageCropperDelegate?
    
    deinit {
        self.originalImage = nil
        self.showImgView   = nil
        self.editedImage   = nil
        self.overlayView   = nil
        self.ratioView     = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cropFrame = CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: self.view.frame.size.width)
        self.limitRatio  =  3.0
        self.originalImage = self.fixOrientation(srcImg: UIImage(named: "pika")!)
        
        self.initView()
        self.initControlBtn()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initView() {
        self.view.backgroundColor = UIColor.black
        
        self.showImgView = UIImageView(frame: CGRect(x: 0,y: 0, width: 320, height: 480))
        self.showImgView?.isMultipleTouchEnabled    = true
        self.showImgView?.isUserInteractionEnabled  = true
        self.showImgView?.image                     = self.originalImage
        
        // scale to fit the screen
        let oriWidth = self.cropFrame!.size.width
        let oriHeight = (self.originalImage?.size.height)! * (oriWidth / (self.originalImage?.size.width)!)
        let oriX = (self.cropFrame?.origin.x)! + ((self.cropFrame?.size.width)! - oriWidth) / 2
        let oriY = (self.cropFrame?.origin.y)! + ((self.cropFrame?.size.height)! - oriHeight) / 2
        
        self.oldFrame = CGRect(x: oriX, y: oriY, width: oriWidth, height: oriHeight)
        self.latestFrame = self.oldFrame
        self.showImgView?.frame = self.oldFrame!
        
        self.largeFrame = CGRect(x: 0, y: 0, width: self.limitRatio! * self.oldFrame!.size.width, height: self.limitRatio! * self.oldFrame!.size.height)
        
        self.addGestureRecognizers()
        self.view.addSubview(self.showImgView!)
        
        self.overlayView = UIView(frame: self.view.bounds)
        self.overlayView?.alpha = 0.5
        self.overlayView?.backgroundColor = .black
        self.overlayView?.isUserInteractionEnabled = false
        self.overlayView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.view.addSubview(self.overlayView!)
        
        self.ratioView = UIView(frame: self.cropFrame!)
        self.ratioView?.layer.borderColor = UIColor.yellow.cgColor
        self.ratioView?.layer.borderWidth = 1.0
        self.ratioView?.autoresizingMask = []
        self.view.addSubview(self.ratioView!)
        
        self.overlayClipping()
    }
    
    /// 初始化两个按钮
    func initControlBtn() {
        let cancelBtn = UIButton(frame: CGRect(x: 0, y: self.view.frame.size.height - 50.0, width: 100, height: 50))
        cancelBtn.backgroundColor = UIColor.black
        cancelBtn.titleLabel?.textColor = UIColor.white
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
        cancelBtn.titleLabel?.textAlignment = .center
        cancelBtn.titleLabel?.lineBreakMode = .byWordWrapping
        cancelBtn.titleLabel?.numberOfLines = 0
        cancelBtn.titleEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        cancelBtn.addTarget(self, action: #selector(cancel(sender:)), for: .touchUpInside)
        self.view.addSubview(cancelBtn)
        
        let confirmBtn = UIButton(frame: CGRect(x: self.view.frame.size.width - 100.0, y: self.view.frame.size.height - 50.0, width: 100, height: 50))
        confirmBtn.backgroundColor = .black
        confirmBtn.titleLabel?.textColor = .white
        confirmBtn.setTitle("OK", for: .normal)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
        confirmBtn.titleLabel?.textAlignment = .center
        confirmBtn.titleLabel?.lineBreakMode = .byWordWrapping
        confirmBtn.titleLabel?.numberOfLines = 0
        confirmBtn.titleEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        confirmBtn.addTarget(self, action: #selector(confirm(sender:)), for: .touchUpInside)
        self.view.addSubview(confirmBtn)
    }
    
    @objc func cancel(sender:AnyObject) {
        self.dismiss(animated: false, completion: nil)
        self.delegate?.imageCropperDidCancel(self)
    }
    
    @objc func confirm(sender:AnyObject) {
        self.dismiss(animated: false, completion: nil)
        self.delegate?.imageCropper(self, editImg: self.getSubImage())
    }
    
    func overlayClipping() {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        
        // Left side of the ratio view
        path.addRect(CGRect(x: 0, y: 0, width: self.ratioView!.frame.origin.x, height: self.overlayView!.frame.size.height))
        
        // Right side of the ratio view
        path.addRect(CGRect(
            x: self.ratioView!.frame.origin.x + self.ratioView!.frame.size.width, y: 0, width: self.overlayView!.frame.size.width - self.ratioView!.frame.origin.x - self.ratioView!.frame.size.width, height: self.overlayView!.frame.size.height))
        
        // Top side of the ratio view
        path.addRect(CGRect(x: 0, y: 0, width: self.overlayView!.frame.size.width, height: self.ratioView!.frame.origin.y))
        
        // Bottom side of the ratio view
        path.addRect(CGRect(x: 0, y: self.ratioView!.frame.origin.y + self.ratioView!.frame.size.height, width: self.overlayView!.frame.size.width, height: self.overlayView!.frame.size.height - self.ratioView!.frame.origin.y + self.ratioView!.frame.size.height))
        
        maskLayer.path = path
        self.overlayView?.layer.mask = maskLayer
        path.closeSubpath()
    }
    
    // MRAK: 缩放手势和平移手势处理
    
    func addGestureRecognizers() {
        // pinch 缩放手势
        let pinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchView(pinchGestureRecognizer:)))
        self.view.addGestureRecognizer(pinchGestureRecognizer)
        
        // pan 平移手势
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panView(panGestureRecognizer:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func pinchView(pinchGestureRecognizer: UIPinchGestureRecognizer) {
        let view = self.showImgView!
        if pinchGestureRecognizer.state == UIGestureRecognizer.State.began || pinchGestureRecognizer.state == UIGestureRecognizer.State.changed {
            view.transform = view.transform.scaledBy(x: pinchGestureRecognizer.scale, y: pinchGestureRecognizer.scale)
            pinchGestureRecognizer.scale = 1
        }
        else if pinchGestureRecognizer.state == UIGestureRecognizer.State.ended {
            var newFrame = self.showImgView!.frame
            newFrame = self.handleScaleOverflow(newFrame: newFrame)
            newFrame = self.handleBorderOverflow(newFrame: newFrame)
            
            UIView.animate(withDuration: BOUNDCE_DURATION, animations: { () -> Void in
                self.showImgView!.frame = newFrame
                self.latestFrame = newFrame
            })
        }
    }
    
    @objc func panView(panGestureRecognizer:UIPanGestureRecognizer) {
        let view = self.showImgView!
        if panGestureRecognizer.state == UIGestureRecognizer.State.began || panGestureRecognizer.state == UIGestureRecognizer.State.changed {
            let absCenterX = self.cropFrame!.origin.x + self.cropFrame!.size.width / 2
            let absCenterY = self.cropFrame!.origin.y + self.cropFrame!.size.height / 2
            let scaleRatio = self.showImgView!.frame.size.width / self.cropFrame!.size.width
            let acceleratorX = 1 - abs(absCenterX - view.center.x) / (scaleRatio * absCenterX)
            let acceleratorY = 1 - abs(absCenterY - view.center.y) / (scaleRatio * absCenterY)
            let translation = panGestureRecognizer.translation(in: view.superview)
            view.center = CGPoint(x: view.center.x + translation.x * acceleratorX, y: view.center.y + translation.y * acceleratorY)
            panGestureRecognizer.setTranslation(CGPoint.zero, in: view.superview)
        }
        else if panGestureRecognizer.state == UIGestureRecognizer.State.ended {
            var newFrame = self.showImgView!.frame
            newFrame = self.handleBorderOverflow(newFrame: newFrame)
            UIView.animate(withDuration: BOUNDCE_DURATION, animations: { () -> Void in
                self.showImgView!.frame = newFrame
                self.latestFrame = newFrame
            })
        }
    }
    
    // MARK:
    
    func handleScaleOverflow(newFrame: CGRect) -> CGRect {
        let oriCenter = CGPoint(x: newFrame.origin.x + newFrame.size.width / 2, y: newFrame.origin.y + newFrame.size
            .height / 2)
        var localNewFrame = newFrame
        if newFrame.size.width < self.oldFrame!.size.width {
            localNewFrame = self.oldFrame!
        }
        if newFrame.size.width > self.largeFrame!.size.width {
            localNewFrame = self.largeFrame!
        }
        localNewFrame.origin.x = oriCenter.x - newFrame.size.width / 2
        localNewFrame.origin.y = oriCenter.y - newFrame.size.height / 2
        return localNewFrame
    }
    
    func handleBorderOverflow(newFrame:CGRect) -> CGRect {
        var localNewFrame = newFrame
        if newFrame.origin.x > self.cropFrame!.origin.x {
            localNewFrame.origin.x = self.cropFrame!.origin.x
        }
        if newFrame.maxX < self.cropFrame!.size.width {
            localNewFrame.origin.x = self.cropFrame!.size.width - newFrame.size.width
        }
        
        if newFrame.origin.y > self.cropFrame!.origin.y {
            localNewFrame.origin.y = self.cropFrame!.origin.y
        }
        if newFrame.maxY < self.cropFrame!.origin.y + self.cropFrame!.size.height {
            localNewFrame.origin.y = self.cropFrame!.origin.y + self.cropFrame!.size.height - newFrame.size.height
        }
        
        if self.showImgView!.frame.size.width > self.showImgView!.frame.size.height && newFrame.size.height <= self.cropFrame!.size.height {
            localNewFrame.origin.y = self.cropFrame!.origin.y + (self.cropFrame!.size.height - newFrame.size.height) / 2
        }
        return localNewFrame
    }
    
    /// 获取当前裁剪的图片
    func getSubImage() -> UIImage {
        let squareFrame = self.cropFrame!
        let scaleRatio = self.latestFrame!.size.width / self.originalImage!.size.width
        var x = (squareFrame.origin.x - self.latestFrame!.origin.x) / scaleRatio
        var y = (squareFrame.origin.y - self.latestFrame!.origin.y) / scaleRatio
        var w = squareFrame.size.width / scaleRatio
        var h = squareFrame.size.height / scaleRatio
        if self.latestFrame!.size.width < self.cropFrame!.size.width {
            let newW = self.originalImage!.size.width
            let newH = newW * (self.cropFrame!.size.height / self.cropFrame!.size.width)
            x = 0;
            y = y + (h - newH) / 2
            w = newH
            h = newH
        }
        if self.latestFrame!.size.height < self.cropFrame!.size.height {
            let newH = self.originalImage!.size.height
            let newW = newH * (self.cropFrame!.size.width / self.cropFrame!.size.height)
            x = x + (w - newW) / 2
            y = 0
            w = newH
            h = newH
        }
        
        let myImageRect = CGRect(x: x, y: y, width: w, height: h)
        let imageRef = self.originalImage!.cgImage
        let subImageRef = imageRef!.cropping(to: myImageRect)
        let size = CGSize(width: myImageRect.size.width, height: myImageRect.size.height)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.draw(subImageRef!, in: myImageRect)
        let smallImage = UIImage(cgImage: subImageRef!)
        UIGraphicsEndImageContext()
        return smallImage
    }
    
    /// 选取的图片可能存在旋转问题，用这个方法处理一下它，确定是正面向上
    func fixOrientation(srcImg: UIImage) -> UIImage {
        if srcImg.imageOrientation == .up {
            return srcImg
        }
        var transform = CGAffineTransform()
        
        switch srcImg.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: srcImg.size.width, y: srcImg.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: srcImg.size.width, y: 0)
            transform = transform.rotated(by: .pi/2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: srcImg.size.height)
            transform = transform.rotated(by: -.pi/2)
        case .up, .upMirrored:
            break
        default:
            break
        }
        
        switch srcImg.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: srcImg.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: srcImg.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        default:
            break
        }
        
        let ctx:CGContext = CGContext(data:             nil,
                                      width:            Int(srcImg.size.width),
                                      height:           Int(srcImg.size.height),
                                      bitsPerComponent: (srcImg.cgImage!).bitsPerComponent,
                                      bytesPerRow:      0,
                                      space:            (srcImg.cgImage!).colorSpace!,
                                      bitmapInfo:       (srcImg.cgImage!).bitmapInfo.rawValue)!
        ctx.concatenate(transform)
        switch srcImg.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(srcImg.cgImage!, in: CGRect(x: 0, y: 0, width: srcImg.size.height, height: srcImg.size.width))
        default:
            ctx.draw(srcImg.cgImage!, in: CGRect(x: 0, y: 0, width: srcImg.size.width, height: srcImg.size.height))
        }
        
        let cgImg = ctx.makeImage()!
        let img = UIImage(cgImage: cgImg)
        
        ctx.closePath()
        return img
    }
    
}


