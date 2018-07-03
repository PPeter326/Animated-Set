//
//  CardView.swift
//  PlayCardTest
//
//  Created by Peter Wu on 5/16/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    var numberOfShapes: Int = 3 { didSet { setNeedsDisplay() } }
    var shape: Shape = .diamond { didSet { setNeedsDisplay() } }
    var color: UIColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)  { didSet { setNeedsDisplay() } }
    var shade: Shade = .solid  { didSet { setNeedsDisplay() } }
    var isFaceUp: Bool = true {
        didSet {
            if isFaceUp {
                backgroundColor =  #colorLiteral(red: 0.2745098174, green: 0.5101637538, blue: 0.1411764771, alpha: 0.7969536493)
            } else {
                backgroundColor = #colorLiteral(red: 0.08967430145, green: 0.3771221638, blue: 0.6760857701, alpha: 1)
            }
            setNeedsDisplay()
        }
    }
    

    enum Shape {
        case oval
        case squiggle
        case diamond
    }
    enum Shade {
        case solid
        case striped
        case unfilled
    }
    
    override func draw(_ rect: CGRect) {
        
        if isFaceUp {
            let rects = divide(rect: self.bounds, numberOfSymbols: numberOfShapes)
            for rect in rects {
                if let context = UIGraphicsGetCurrentContext() {
                    context.saveGState()
                    let shapePath = createShape(rect: rect)
                    shapePath.addClip()
                    createShade(path: shapePath, rect: rect)
                    context.restoreGState()
                }
            }
        }
    }

    
    
    func showNoSelection() {
        self.layer.borderWidth = self.frame.width * SizeRatio.defaultBorderWidthRatio
        self.layer.borderColor = BorderColor.defaultBorderColor
    }
    func showSelection() {
        self.layer.borderWidth = self.frame.width * SizeRatio.highlightBorderWidthRatio
        self.layer.borderColor = BorderColor.selectedBorderColor
    }
    func showMatch() {
        self.layer.borderWidth = self.frame.width * SizeRatio.highlightBorderWidthRatio
        self.layer.borderColor =  BorderColor.matchedBorderColor
    }
    func showNoMatch() {
        self.layer.borderWidth = self.frame.width * SizeRatio.highlightBorderWidthRatio
        self.layer.borderColor =  BorderColor.mismatchBorderColor
    }
    
    func insetFrame() {
        let newFrame = self.frame.insetBy(dx: self.frame.width * SizeRatio.insetWidthRatio, dy: self.frame.height * SizeRatio.insetHeightRatio)
        self.frame = newFrame
    }
    private func divide(rect: CGRect, numberOfSymbols: Int) -> [CGRect] {
        // determine rectangle ratio of width and height.  If width is wider than height, then divide across horizontally
        let ratio = rect.size.width / rect.size.height
        // determine origin of first rect based on the number of rects
        // If there's only one, then the one and only rect should be in the center (x = rect.midX - width * 1 / 2)
        // if two, then the two should be split in the center (x = rect.midX - width * 2 / 2)
        // If three, then each one should be equally distributed (x = rect.midX - width * 3 / 2)
        var rects = [CGRect]()
        if ratio >= 1.0 { // width > height: horizontal
            let width = rect.size.width / 3.0
            let height = width / 8 * 5
            var rectOrigin = CGPoint(x: rect.midX - width * CGFloat(numberOfSymbols) * 1 / 2, y: rect.midY - height / 2)
            let size = CGSize(width: width, height: height)
            for _  in 1...numberOfSymbols {
                let rect = CGRect(origin: rectOrigin, size: size).insetBy(dx: width / 10, dy: height / 10)
                rects.append(rect)
                rectOrigin.x += width
            }
        } else { // height > width: vertical
            let height = rect.size.height / 3.0
            let width = height / 5 * 8
            let size = CGSize(width: width, height: height)
            var rectOrigin = CGPoint(x: rect.midX - width / 2, y: rect.midY - height * CGFloat(numberOfSymbols) * 1 / 2)
            for _  in 1...numberOfSymbols {
                let rect = CGRect(origin: rectOrigin, size: size).insetBy(dx: width / 10, dy: height / 10)
                rects.append(rect)
                rectOrigin.y += height
            }
        }
        return rects
    }
    
    private func createShape(rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = self.frame.size.width / 30
        switch shape {
            case .diamond: createDiamondShape(path: path, rect: rect, color: self.color)
            case .oval: createOvalShape(path: path, rect: rect, color: self.color)
            case .squiggle: createSquiggleShape(path: path, rect: rect, color: self.color)
        }
        return path
    }
    
    private func createShade(path: UIBezierPath, rect: CGRect) {
        switch shade {
            case .solid: createFilledShape(path: path, color: self.color)
            case .striped: createStripedShape(path: path, rect: rect, color: self.color)
            case .unfilled: break
        }
    }
    
    private func createStripedShape(path: UIBezierPath, rect: CGRect, color: UIColor) {
        path.removeAllPoints()
        for xPosition in stride(from: rect.origin.x, to: rect.maxX, by: rect.size.width / 10) {
            path.move(to: CGPoint(x: xPosition, y: rect.origin.y))
            path.addLine(to: CGPoint(x: xPosition, y: rect.maxY))
        }
        color.setStroke()
        path.stroke()
    }
    private func createFilledShape(path: UIBezierPath, color: UIColor) {
        //        path.removeAllPoints()
        color.setFill()
        path.fill()
    }
    
    private func createSquiggleShape(path: UIBezierPath, rect: CGRect, color: UIColor) {
        path.removeAllPoints()
        let quadControlPointLength = rect.width / 8
        path.move(to: CGPoint(x: rect.origin.x + quadControlPointLength, y: rect.origin.y + quadControlPointLength * 2))
        path.addCurve(to: CGPoint(x: rect.maxX - quadControlPointLength, y: rect.origin.y + quadControlPointLength * 2), controlPoint1: CGPoint(x: rect.origin.x + rect.width / 3, y: rect.origin.y), controlPoint2: CGPoint(x: rect.maxX - rect.width / 3, y: rect.maxY - rect.height / 6))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - quadControlPointLength, y: rect.maxY - quadControlPointLength), controlPoint: CGPoint(x: rect.maxX, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.origin.x + quadControlPointLength, y: rect.maxY - quadControlPointLength), controlPoint1: CGPoint(x: rect.maxX - rect.width / 3, y: rect.maxY), controlPoint2: CGPoint(x: rect.midX - quadControlPointLength, y: rect.origin.y + rect.height / 3))
        path.addQuadCurve(to: CGPoint(x: rect.origin.x + quadControlPointLength, y: rect.origin.y + quadControlPointLength * 2), controlPoint: CGPoint(x: rect.origin.x, y: rect.midY + quadControlPointLength))
        path.lineJoinStyle = .round
        path.close()
        color.setStroke()
        path.stroke()
    }
    private func createDiamondShape(path: UIBezierPath, rect: CGRect, color: UIColor) {
        path.removeAllPoints()
        let verticalSafeSpace = rect.size.height / 8
        let horizontalSafeSpace = rect.size.width / 8
        path.move(to: CGPoint(x: rect.midX, y: rect.origin.y + verticalSafeSpace))
        path.addLine(to: CGPoint(x: rect.maxX - horizontalSafeSpace, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - verticalSafeSpace))
        path.addLine(to: CGPoint(x: rect.minX + horizontalSafeSpace, y: rect.midY))
        path.close()
        color.setStroke()
        path.stroke()
    }
    
    private func createOvalShape(path: UIBezierPath, rect: CGRect, color: UIColor) {
        path.removeAllPoints()
        let controlPointLength = rect.width / 8
        path.move(to: CGPoint(x: (rect.origin.x + controlPointLength), y: rect.origin.y + controlPointLength))
        path.addLine(to: CGPoint(x: (rect.maxX - controlPointLength), y: rect.origin.y + controlPointLength))
        path.addQuadCurve(to: CGPoint(x: (rect.maxX - controlPointLength), y: rect.maxY - controlPointLength), controlPoint: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: (rect.origin.x + controlPointLength), y: rect.maxY - controlPointLength))
        path.addQuadCurve(to: CGPoint(x: (rect.origin.x + controlPointLength), y: rect.origin.y + controlPointLength), controlPoint: CGPoint(x: rect.minX, y: rect.midY))
        path.close()
        color.setStroke()
        path.stroke()
    }
    
    private struct SizeRatio {
        static var insetWidthRatio: CGFloat = 0.10
        static var insetHeightRatio: CGFloat = 0.10
        static var defaultBorderWidthRatio: CGFloat = 0.01
        static var highlightBorderWidthRatio: CGFloat = 0.0667
    }
    private struct BorderColor {
        static var defaultBorderColor: CGColor = UIColor.black.cgColor
        static var mismatchBorderColor: CGColor = UIColor.red.cgColor
        static var selectedBorderColor: CGColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1).cgColor
        static var matchedBorderColor: CGColor = UIColor.green.cgColor
    }

}
