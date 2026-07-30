// Clic de synthèse via CGEvent.
// Raison d'être : `click at {x, y}` de System Events s'exécute sans erreur mais
// ne délivre aucun événement sur macOS 26. La forme `click <élément>` marche,
// donc ce binaire n'est utile que quand aucun élément d'accessibilité ne
// correspond à la cible (canvas, jeu, app non instrumentée).
//
// Coordonnées en POINTS (repère écran, origine haut-gauche) — pas en pixels
// physiques. `screencapture` sort des pixels : diviser par le facteur d'échelle.
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3, let x = Double(args[1]), let y = Double(args[2]) else {
    FileHandle.standardError.write(Data("usage: click <x> <y> [left|right] [count]\n".utf8))
    exit(2)
}
let right = args.count > 3 && args[3] == "right"
let count = max(1, args.count > 4 ? Int(args[4]) ?? 1 : 1)
let pt = CGPoint(x: x, y: y)
let button: CGMouseButton = right ? .right : .left
let down: CGEventType = right ? .rightMouseDown : .leftMouseDown
let up: CGEventType = right ? .rightMouseUp : .leftMouseUp

// ponytail: pas de drag ni de scroll — c'est un autre geste, à ajouter le jour où on en a besoin.
CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: button)?
    .post(tap: .cghidEventTap)
for i in 1...count {
    for type in [down, up] {
        guard let e = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: pt, mouseButton: button)
        else { FileHandle.standardError.write(Data("CGEvent creation failed\n".utf8)); exit(1) }
        e.setIntegerValueField(.mouseEventClickState, value: Int64(i))
        e.post(tap: .cghidEventTap)
    }
    usleep(30_000)
}
