//
//  ViewController.swift
//  DrawingApp
//
//  Created by B_Litwin on 9/27/18.
//  Copyright © 2018 B_Litwin. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    var touchView: TouchView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        touchView = TouchView(frame: CGRect(x: 0, y: 100, width: 320, height: 300))
        view.addSubview(touchView)
        let button = UIButton()
        button.frame = CGRect(x: 100, y: 0, width: 100, height: 100)
        view.addSubview(button)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(t), for: .touchDown)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func t() {
        CameraHandler.shared.showActionSheet(vc: self)
        //touchView.redraw()
    }
    
}




class TouchView: UIView {
    var lineColor: UIColor!
    var lineWidth: CGFloat!
    var path: UIBezierPath!
    var startingPoint: CGPoint!
    
    var touchPoint:CGPoint! {
        didSet {
            allPoints.append(touchPoint)
        }
    }
    
    var allPoints: [CGPoint] = []
    
    override func layoutSubviews() {
        clipsToBounds = true
        lineWidth = 15
        lineColor = .red
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // get the touch position when user starts drawing
        let touch = touches.first
        startingPoint = touch?.location(in: self)
        allPoints = [startingPoint]
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        touchPoint = touch?.location(in: self)
        path = UIBezierPath()
        path.move(to: startingPoint)
        path.addLine(to: touchPoint)
        startingPoint = touchPoint
        drawShapeLayer()
    }
    
    func drawShapeLayer() {
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapeLayer)
        self.setNeedsDisplay()
        
    }
    
    func redraw() {
        self.layer.sublayers?.forEach({ layer in
            layer.transform = CATransform3DMakeScale(0.1, 0.1, 1.0)
        })
    }
    
    func clearCanvas() {
        path.removeAllPoints()
        self.layer.sublayers = nil
        self.setNeedsDisplay()
    }
    
}


extension CGRect{
    var center: CGPoint {
        return CGPoint( x: self.size.width/2.0,y: self.size.height/2.0)
    }
}
extension CGPoint{
    func vector(to p1:CGPoint) -> CGVector{
        return CGVector(dx: p1.x-self.x, dy: p1.y-self.y)
    }
}

extension UIBezierPath{
    func moveCenter(to:CGPoint) -> Self{
        let bound  = self.cgPath.boundingBox
        let center = bounds.center
        
        let zeroedTo = CGPoint(x: to.x-bound.origin.x, y: to.y-bound.origin.y)
        let vector = center.vector(to: zeroedTo)
        
        offset(to: CGSize(width: vector.dx, height: vector.dy))
        return self
    }
    
    func offset(to offset:CGSize) -> Self{
        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
        applyCentered(transform: t)
        return self
    }
    
    func fit(into:CGRect) -> Self{
        let bounds = self.cgPath.boundingBox
        
        let sw     = into.size.width/bounds.width
        let sh     = into.size.height/bounds.height
        let factor = min(sw, max(sh, 0.0))
        
        return scale(x: factor, y: factor)
    }
    
    func scale(x:CGFloat, y:CGFloat) -> Self{
        let scale = CGAffineTransform(scaleX: x, y: y)
        applyCentered(transform: scale)
        return self
    }
    
    
    func applyCentered(transform: @autoclosure () -> CGAffineTransform ) -> Self{
        let bound  = self.cgPath.boundingBox
        let center = CGPoint(x: bound.midX, y: bound.midY)
        var xform  = CGAffineTransform.identity
        
        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        xform = xform.concatenating(transform())
        xform = xform.concatenating( CGAffineTransform(translationX: center.x, y: center.y))
        apply(xform)
        
        return self
    }
}


class CameraHandler: NSObject{
    static let shared = CameraHandler()
    
    fileprivate var currentVC: UIViewController!
    
    //MARK: Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?
    
    func camera()
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .camera
            currentVC.present(myPickerController, animated: true, completion: nil)
        }
        
    }
    
    func photoLibrary()
    {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .photoLibrary
            currentVC.present(myPickerController, animated: true, completion: nil)
        }
        
    }
    
    func showActionSheet(vc: UIViewController) {
        currentVC = vc
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.camera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.photoLibrary()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        vc.present(actionSheet, animated: true, completion: nil)
    }
    
}


extension CameraHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imagePickedBlock?(image)
        }else{
            print("Something went wrong")
        }
        currentVC.dismiss(animated: true, completion: nil)
    }
    
}


