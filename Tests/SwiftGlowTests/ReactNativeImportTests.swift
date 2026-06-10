import XCTest
@testable import SwiftGlow

final class ReactNativeImportTests: XCTestCase {
    func testTopLevelCommaSplitterKeepsRGBAColorsTogether() {
        let values = splitDemoColorList("rgba(238, 255, 0, 1), rgba(79, 255, 0, 1), #FFFFFF")
        XCTAssertEqual(values, [
            "rgba(238, 255, 0, 1)",
            "rgba(79, 255, 0, 1)",
            "#FFFFFF"
        ])
    }
}

private func splitDemoColorList(_ text: String) -> [String] {
    var values: [String] = []
    var current = ""
    var parenthesisDepth = 0

    for character in text {
        if character == "(" {
            parenthesisDepth += 1
            current.append(character)
        } else if character == ")" {
            parenthesisDepth = max(0, parenthesisDepth - 1)
            current.append(character)
        } else if character == "," && parenthesisDepth == 0 {
            let value = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                values.append(value)
            }
            current = ""
        } else {
            current.append(character)
        }
    }

    let lastValue = current.trimmingCharacters(in: .whitespacesAndNewlines)
    if !lastValue.isEmpty {
        values.append(lastValue)
    }
    return values
}
