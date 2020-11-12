//
//  FaceRead.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

struct Point: Decodable {
    let x: Double
    let y: Double
}

struct Line: Decodable {
    let start: Point
    let end: Point
}

struct UndoverlineJson: Decodable {
    let line: Line
    let code: UInt16
    
    var letter: FaceLetter? {
        get {
            return FaceLetter.A
        }
    }
}

class FaceReadJson: Decodable {
    let underline: UndoverlineJson?;
    let overline: UndoverlineJson?;
    let orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl?;
    let ocrLetterCharsFromMostToLeastLikely: String;
    let ocrDigitCharsFromMostToLeastLikely: String;
    let center: Point;
    
    var letter: FaceLetter { get {
        // FIXME
        return FaceLetter.A
    }}

    var digit: FaceDigit { get {
        // FIXME
        return FaceDigit.D1
    }}
    

    func toFace() -> Face {
        return Face(
            letter: letter,
            digit: digit,
            orientationAsLowercaseLetterTrbl: orientationAsLowercaseLetterTrbl ?? FaceOrientationLetterTrbl.Top)
    }
}
