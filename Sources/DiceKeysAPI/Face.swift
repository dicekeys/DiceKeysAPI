//
//  Face.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

extension FaceOrientationLetterTrbl {
    func rotate90() -> FaceOrientationLetterTrbl {
        switch self {
            case FaceOrientationLetterTrbl.Top: return FaceOrientationLetterTrbl.Right
            case FaceOrientationLetterTrbl.Right: return FaceOrientationLetterTrbl.Bottom
            case FaceOrientationLetterTrbl.Bottom: return FaceOrientationLetterTrbl.Left
            case FaceOrientationLetterTrbl.Left: return FaceOrientationLetterTrbl.Top
        }
    }
}

struct Face {
    let letter: FaceLetter
    let digit: FaceDigit
    let orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl
    
    func rotate90() -> Face {
        return Face(letter: letter, digit: digit, orientationAsLowercaseLetterTrbl: self.orientationAsLowercaseLetterTrbl.rotate90()
        )
    }
}


