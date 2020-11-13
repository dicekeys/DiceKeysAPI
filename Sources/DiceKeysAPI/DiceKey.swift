//
//  DiceKey.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

typealias Tuple25<T> = (
    T, T, T, T, T,
    T, T, T, T, T,
    T, T, T, T, T,
    T, T, T, T, T,
    T, T, T, T, T
)

typealias FaceTuple = Tuple25<Face>

let clockwise90DegreeRotationIndexesFor5x5Grid = [
    20, 15, 10, 5, 0,
    21, 16, 11, 6, 1,
    22, 17, 12, 7, 2,
    23, 18, 13, 8, 3,
    24, 19, 14, 9, 4
]

class DiceKey {
    let faces: [Face]
    
    var faceTuple: FaceTuple { get {
        return (
            faces[0], faces[1], faces[2], faces[3], faces[4],
            faces[5], faces[6], faces[7], faces[8], faces[9],
            faces[10], faces[11], faces[12], faces[13], faces[14],
            faces[15], faces[16], faces[17], faces[18], faces[19],
            faces[20], faces[21], faces[22], faces[23], faces[24]
        )
    }}

    init(_ faces: [Face]) {
        precondition(faces.count == 25)
        self.faces = faces;
    }
    
    func withoutOrientations() -> DiceKey {
        return DiceKey(
            faces.map() {
                Face(
                    letter: $0.letter,
                    digit: $0.digit,
                    orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Top
                )
            }
        )
    }
        
    func rotatedClockwise90Degrees() -> DiceKey {
        return DiceKey(
            clockwise90DegreeRotationIndexesFor5x5Grid.map() { index in
                Face(
                    letter: faces[index].letter,
                    digit: faces[index].digit,
                    orientationAsLowercaseLetterTrbl: faces[index].orientationAsLowercaseLetterTrbl.rotate90() )

            }
        )
    }
    
    func toHumanReadableForm(includeOrientations: Bool) -> String {
        return faces.map() { face -> String in
            face.letter.rawValue +
            face.digit.rawValue +
                (includeOrientations ? face.orientationAsLowercaseLetterTrbl.rawValue : "")
        }.joined(separator: "") as String
    }
    
    func rotatedToCanonicalForm(
      includeOrientations: Bool
    ) -> DiceKey {
        var candidateDiceKey = self
        var diceKeyWithEarliestHumanReadableForm = candidateDiceKey
        var earliestHumanReadableForm = diceKeyWithEarliestHumanReadableForm.toHumanReadableForm(includeOrientations: includeOrientations)
        for _ in 1...3 {
            candidateDiceKey = candidateDiceKey.rotatedClockwise90Degrees()
            let humanReadableForm = candidateDiceKey.toHumanReadableForm(includeOrientations: includeOrientations)
            if (humanReadableForm < earliestHumanReadableForm) {
                earliestHumanReadableForm = humanReadableForm
                diceKeyWithEarliestHumanReadableForm = candidateDiceKey
            }
        }
        return diceKeyWithEarliestHumanReadableForm
    }
    
    func toSeed(includeOrientations: Bool) -> String {
        return rotatedToCanonicalForm(includeOrientations: includeOrientations)
            .toHumanReadableForm(includeOrientations: includeOrientations)
    }
    
}
