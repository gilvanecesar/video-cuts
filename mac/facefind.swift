// facefind — where are the faces in this image?
//
// Uses the Vision framework that ships with macOS: no model to download, no
// opencv, no Python wheel. Prints one JSON object per image on stdout:
//   {"file": "...", "faces": [{"x": 0.53, "y": 0.41, "w": 0.18, "h": 0.31}]}
// Coordinates are fractions of the image, origin top-left, so the caller never
// has to know Vision flips the y axis.
import Foundation
import Vision
import AppKit

struct Box: Encodable { let x, y, w, h: Double }
struct Result: Encodable { let file: String; let faces: [Box] }

func faces(in path: String) -> [Box] {
    guard let image = NSImage(contentsOfFile: path),
          let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else { return [] }
    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: cg, options: [:])
    do { try handler.perform([request]) } catch { return [] }
    return (request.results ?? []).map { o in
        let b = o.boundingBox           // normalised, origin bottom-left
        return Box(x: Double(b.midX), y: Double(1 - b.midY),
                   w: Double(b.width), h: Double(b.height))
    }
}

let out = CommandLine.arguments.dropFirst().map {
    Result(file: $0, faces: faces(in: $0))
}
let enc = JSONEncoder()
print(String(data: try! enc.encode(out), encoding: .utf8)!)
