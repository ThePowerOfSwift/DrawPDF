//
//  VPDFTableCreation.swift
//  VTablePDFCreation
//
//  Created by vishal on 11/22/17.
//  Copyright © 2017 vishal. All rights reserved.
//

import UIKit
import Foundation

struct PageInfo {
    var PagePadding : CGFloat = 20.0
    var ColumnDataPadding : CGFloat = 3.0
}

public class VPDFTableCreation: NSObject {
    
    private var pageSize = CGSize()
    private var pdfPath = String()
    private var pageInfo = PageInfo()
    private var alignment : NSTextAlignment?
    //MARK: =================  PDF Creation  =======================
    
    public override init() {
        super.init()
    }
    
    open func CreatePDFAndSaveDocumentDirectory(pdfName:String, width:CGFloat, height:CGFloat) {
        pageSize = CGSize(width: width, height: height)
        let newPDFName = "\(pdfName).pdf"
        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = paths[0]
        pdfPath = URL.init(fileURLWithPath: documentsDirectory).appendingPathComponent(newPDFName).path
        UIGraphicsBeginPDFContextToFile(pdfPath, CGRect.zero, nil)
        beginPDFPage()
    }
    
    open func getPDFFile() -> String {
        return pdfPath
    }
    
    fileprivate func beginPDFPage() {
        UIGraphicsBeginPDFPageWithInfo(CGRect.init(x: 0, y: 0, width: pageSize.width, height: pageSize.height), nil)
    }
    
    fileprivate func finishPDF() {
        UIGraphicsEndPDFContext();
    }
    
    fileprivate func drawTopLine(yPOS:CGFloat) -> CGPoint {
        let from = CGPoint(x: pageInfo.PagePadding, y: yPOS)
        let to = CGPoint(x: pageSize.width - pageInfo.PagePadding, y: yPOS)
        drawLine(from: from, to: to)
        return to
    }
    
    fileprivate func drawColumn(_ ColumnPositionY: CGFloat, EachColumnWidth:[Int]){
        var ColumnPositionX = Int()
        for i in 0...EachColumnWidth.count {
            if i == 0{
                ColumnPositionX = Int(pageInfo.PagePadding)
            }else{
                ColumnPositionX = ColumnPositionX + EachColumnWidth[i-1]
            }
            let from = CGPoint(x: CGFloat(ColumnPositionX), y: pageInfo.PagePadding)
            let to = CGPoint(x: CGFloat(ColumnPositionX), y: ColumnPositionY)
            drawLine(from: from, to: to)
        }
    }
    
    fileprivate func drawText(_ text: String, Frame: CGRect, withAttributes:[NSAttributedStringKey : Any]) {
        text.draw(in: Frame, withAttributes:withAttributes)
    }
    
    open func DrawPDF(TotalData:[[String]],headerData:[String],EachColumnWidth:[Int], fontSize: Float, textAlignment alignment: NSTextAlignment,Viewcontroller:UIViewController)  {
        self.alignment = alignment
        let sum = EachColumnWidth.reduce(0, +)
        if sum != Int(pageSize.width) - Int(pageInfo.PagePadding*2)
        {
            ShowAlert(message: "Sum of columnWidth must be Equals to width of pagesize minus 40",ViewController:Viewcontroller)
            return
        }else if (EachColumnWidth.count != headerData.count){
            ShowAlert(message: "headerData count must be equal with EachColumnWidth count",ViewController:Viewcontroller)
            return
        }
        var font: UIFont?
        var isHeaderRequireFromSecondPage : Bool = true
        var arrDataWithHeader = [[String]]()
        arrDataWithHeader.append(headerData)
        var i = 0
        for item in TotalData {
            if item.count == EachColumnWidth.count {
                arrDataWithHeader.append(item)
            }else{
                ShowAlert(message: "TotalData index of \(i) object count must be equal with EachColumnWidth count",ViewController:Viewcontroller)
                return
            }
            i += 1
        }
        
        var yPOSEachString = CGFloat()
        
        yPOSEachString = drawTopLine(yPOS: pageInfo.PagePadding).y
        var pageCount = 1
        
        for eachRowitems in arrDataWithHeader {
            var columnCount : Int = 0
            var xPOSEachString = CGFloat()
            
            if isHeaderRequireFromSecondPage {
                font = fontBoldForPDF(withSize: fontSize)
            }else{
                font = fontForPDF(withSize: fontSize)
            }
            
            let tupleSizeAndAttribute = FindStringHeightWithAttribute(font: font!, texts: eachRowitems, Width: EachColumnWidth)
            
            if yPOSEachString + tupleSizeAndAttribute.0 > pageSize.height - pageInfo.PagePadding{
                drawColumn(yPOSEachString, EachColumnWidth: EachColumnWidth)
                beginPDFPage()
                pageCount += 1
                yPOSEachString = CGFloat()
                yPOSEachString = drawTopLine(yPOS: pageInfo.PagePadding).y
            }
            
            for rowItem in eachRowitems{
                isHeaderRequireFromSecondPage = false
                let columnWidth = CGFloat(EachColumnWidth[columnCount])
                xPOSEachString = columnCount == 0 ? pageInfo.PagePadding : (xPOSEachString + CGFloat(EachColumnWidth[columnCount-1]))
                let stringHeight = FindStringHeight(font: font!, text: rowItem, Width: columnWidth-pageInfo.ColumnDataPadding)
                var yPOS = CGFloat()
                if stringHeight < tupleSizeAndAttribute.0{
                    yPOS = (tupleSizeAndAttribute.0/2) - (stringHeight/2) + yPOSEachString + pageInfo.ColumnDataPadding
                }else{
                    yPOS = yPOSEachString + pageInfo.ColumnDataPadding
                }
                let rect = CGRect.init(x: xPOSEachString+pageInfo.ColumnDataPadding, y:yPOS, width:columnWidth-(pageInfo.ColumnDataPadding*2), height: tupleSizeAndAttribute.0)
                drawText(rowItem, Frame:rect, withAttributes:tupleSizeAndAttribute.1)
                columnCount += 1
            }
            let biggestHeight = tupleSizeAndAttribute.0 + yPOSEachString + (2*pageInfo.ColumnDataPadding)
            yPOSEachString = drawTopLine(yPOS: biggestHeight).y
        }
        drawColumn(yPOSEachString, EachColumnWidth: EachColumnWidth)
        finishPDF()
    }
    
    fileprivate func FindStringHeightWithAttribute(font : UIFont,texts:[String],Width:[Int]) -> (CGFloat,[NSAttributedStringKey : Any]) {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.lineBreakMode = .byWordWrapping
        paragraphStyle?.alignment = self.alignment!
        
        let attributes = [NSAttributedStringKey.font: font, NSAttributedStringKey.paragraphStyle: paragraphStyle!] as [NSAttributedStringKey : Any]
        
        var heights = [CGFloat]()
        var i = 0
        for text in texts {
            let stringSize = text.boundingRect(with: CGSize(width:CGFloat(Width[i]) - pageInfo.ColumnDataPadding, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
            heights.append(stringSize.height)
            i += 1
        }
        return (heights.max()!,attributes)
    }
    
    fileprivate func FindStringHeight(font : UIFont,text:String,Width:CGFloat) -> CGFloat {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.lineBreakMode = .byWordWrapping
        paragraphStyle?.alignment = self.alignment!
        
        let attributes = [NSAttributedStringKey.font: font, NSAttributedStringKey.paragraphStyle: paragraphStyle!] as [NSAttributedStringKey : Any]
        
        let stringSize = text.boundingRect(with: CGSize(width:CGFloat(Width), height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        return stringSize.height
    }
    
    fileprivate func fontForPDF(withSize fontSize: Float) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(fontSize))
    }
    
    fileprivate func fontBoldForPDF(withSize fontSize: Float) -> UIFont {
        return UIFont.boldSystemFont(ofSize: CGFloat(fontSize))
    }
    
    fileprivate func drawLine(from: CGPoint, to: CGPoint) {
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: CGPoint(x: from.x, y: from.y))
        context?.addLine(to: CGPoint(x: to.x, y: to.y))
        context?.strokePath()
    }
    
    //MARK: =================  Third Party Integration  =======================
    fileprivate func ShowAlert(message:String,ViewController:UIViewController){
        print(message)
    }
}

