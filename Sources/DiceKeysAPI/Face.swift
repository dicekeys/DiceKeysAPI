//
//  Face.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

//enum FaceLetter: String, Codable {
//    case A, B, C, D, F, G, H, I, J, K, L, M, N, O, P, R, S, T, U, V, W, X, Y, Z
//}
//
//enum FaceDigit: String, Codable {
//    case D1 = "1"
//    case D2 = "2"
//    case D3 = "3"
//    case D4 = "4"
//    case D5 = "5"
//    case D6 = "6"
//}
//
//enum FaceOrientationLetterTrbl: String, Codable {
//    case Top = "t"
//    case Right = "r"
//    case Bottom = "b"
//    case Left = "l"
//}

struct Face {
    let letter: FaceLetter
    let digit: FaceDigit
    let orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl
}
