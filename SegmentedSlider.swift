//
//  SegmentedSlider.swift
//  ShenYangDaily
//
//  Created by 王萌 on 2019/7/8.
//  Copyright © 2019年 SIASUN. All rights reserved.
//

import UIKit

protocol SegmentedSliderDelegate {
    
    /// 选择完成回调
    ///
    /// - Parameter segment: 已选择的段数
    func segmentedSliderDidFinishSelect(segment: Int)
}

//baseline前边距
let leadingSpace: CGFloat = 30.0
//baseline下边距
let bottomSpace: CGFloat = 20.0
//baseline高度,line宽度
let lineWidth: CGFloat = 0.5
//line高度
let lineHeight: CGFloat = 10.0
//滑块半径
let sliderBarRadius: CGFloat = 26.0
//label高度
let labelHeight: CGFloat = 20.0

class SegmentedSlider: UIView {
    var delegate: SegmentedSliderDelegate?
    
    /// 分几个点,默认为4个点(3段, 是4个点. 类似|----|----|----|)
    var segmentCount: Int = 4 {
        willSet {
            assert(newValue > 0, "segmentCount属性应该>0")
        }
    }
    
//  /// 每个点上显示的文字, 如果不需要显示, 传递空字符串""
//    var textArr = ["", "", "", ""]

    /// 还是用NSAttributedString吧,防止幺蛾子
    var textArr: Array<NSAttributedString>?
    
    /// 小滑块颜色,默认为蓝色
    var sliderBarColor = UIColor.init(red: 36.0/255, green: 159.0/255, blue: 244.0/255, alpha: 1.0)
    
    /// 如果小滑块不在初始位置, 需要传递此参数
    var selectedIndex = 0 {
        willSet {
            assert(newValue >= 0, "selectedIndex属性应该>=0")
        }
    }
    
    /// 保存每个点的x坐标,用于计算后返回当前滑块在第几个点上
    private var positionArr = Array<CGFloat>()
    
    /// 基线
    private lazy var baseLineView: UIView = {
        let frame = CGRect.init(x: leadingSpace, y: self.frame.height - bottomSpace, width: self.frame.width - leadingSpace*2, height: lineWidth)
        let view = UIView.init(frame: frame)
        let color = UIColor.init(red: 81.0/255, green: 81.0/255, blue: 81.0/255, alpha: 1.0)
        view.backgroundColor = color
        
        //记录是否需要添加label
        var flag = false
        if let textArr = self.textArr {
            assert(segmentCount == textArr.count, "点数和每个点上对应的文字不匹配,请检查textArr.count是否等于segmentCount")
            flag = true
        }
        for index in 0..<segmentCount {
            let xPos:CGFloat = leadingSpace + CGFloat(index)*(frame.width/CGFloat(segmentCount-1))
            let lineFrame = CGRect.init(x: xPos, y: frame.origin.y - lineHeight, width: lineWidth, height: lineHeight)
            let line = UIView.init(frame: lineFrame)
            line.backgroundColor = color
            self.addSubview(line)
            self.positionArr.append(xPos)
            
            if flag {
                let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: frame.width/CGFloat(segmentCount-1), height: labelHeight))
                label.textAlignment = .center
                label.attributedText = textArr![index]
                label.center = CGPoint.init(x: lineFrame.origin.x, y: lineFrame.origin.y - labelHeight)
                self.addSubview(label)
            }
        }
        return view
    }()
    
    /// 滑块
    private lazy var controlPoint: UIView = {
        assert(selectedIndex < segmentCount, "默认滑块位置超出范围,请确认selectedIndex小于segmentCount")
        //先获得第一个点的坐标
        let x = leadingSpace + CGFloat(selectedIndex)*(self.baseLineView.frame.width/CGFloat(segmentCount-1))
        let point = CGPoint.init(x: x, y: self.baseLineView.frame.origin.y)
        let view = UIView.init(frame: CGRect.init(x: 0.0, y: 0.0, width: sliderBarRadius, height:sliderBarRadius))
        view.backgroundColor = sliderBarColor
        view.center = point
        view.layer.cornerRadius = sliderBarRadius/2
        view.layer.masksToBounds = true
        self.setShadow(view)
        
        //添加手势
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGesture(_:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    /// 需要外部调用此方法来显示
    func show() {
        self.addSubview(self.baseLineView)
        self.addSubview(self.controlPoint)
        addAction()    
    }
    
    private func addAction() {
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapGesture(_:)))
        self.addGestureRecognizer(tap)
    }
    
    private func setShadow(_ view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize.init(width: 0, height: -3)
        view.layer.shadowOpacity = 0.1;
        view.layer.shadowRadius = 2;
    }
    
    /// 点击/滑动事件结束后,将滑块固定在指定位置上
    ///
    /// - Parameter pos: 点击的坐标点
    private func resetControlPosition(_ pos: CGPoint) {
        //先计算每个点的差值
        let arr = positionArr.map { abs($0-pos.x) }
        //取得最小的点,即为离点击最近的line
        let min = arr.min()
        //获取索引,获得第几个点
        let index = arr.index(of: min!)
        //改变滑块位置
        self.controlPoint.center = CGPoint.init(x: positionArr[index!], y: self.baseLineView.frame.origin.y)
        //回调
        if let delegate = self.delegate {
            delegate.segmentedSliderDidFinishSelect(segment: index!)
        }
    }
    
    @objc private func tapGesture(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        if point.x > leadingSpace && point.x < self.frame.width - leadingSpace {
            if tap.state == .ended {
                resetControlPosition(point)
            }
        }
    }
    
    @objc private func panGesture(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self)
        if point.x > leadingSpace && point.x < self.frame.width - leadingSpace {
            self.controlPoint.center = CGPoint.init(x: point.x, y: self.baseLineView.frame.origin.y)
            if pan.state == .ended {
                resetControlPosition(point)
            }
        }
    }
}
