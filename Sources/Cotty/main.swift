import CGhosttyVT
import Foundation

struct GhosttyFailure: Error, CustomStringConvertible {
    let operation: String
    let result: GhosttyResult

    var description: String {
        "\(operation) failed with GhosttyResult(\(result.rawValue))"
    }
}

@inline(__always)
func requireSuccess(_ result: GhosttyResult, _ operation: String) throws {
    guard result == GHOSTTY_SUCCESS else {
        throw GhosttyFailure(operation: operation, result: result)
    }
}

func encodeControlC() throws -> String {
    var encoder: GhosttyKeyEncoder?
    try requireSuccess(ghostty_key_encoder_new(nil, &encoder), "ghostty_key_encoder_new")
    defer { ghostty_key_encoder_free(encoder) }

    var event: GhosttyKeyEvent?
    try requireSuccess(ghostty_key_event_new(nil, &event), "ghostty_key_event_new")
    defer { ghostty_key_event_free(event) }

    ghostty_key_event_set_action(event, GHOSTTY_KEY_ACTION_PRESS)
    ghostty_key_event_set_key(event, GHOSTTY_KEY_C)
    ghostty_key_event_set_mods(event, GhosttyMods(GHOSTTY_MODS_CTRL))

    var buffer = [CChar](repeating: 0, count: 128)
    var written = 0
    try requireSuccess(
        ghostty_key_encoder_encode(encoder, event, &buffer, buffer.count, &written),
        "ghostty_key_encoder_encode"
    )

    return String(decoding: buffer.prefix(written).map { UInt8(bitPattern: $0) }, as: UTF8.self)
}

do {
    let sequence = try encodeControlC()
    let bytes = sequence.utf8.map { String(format: "0x%02x", $0) }.joined(separator: " ")
    print("libghostty-vt linked: Ctrl+C encodes to [\(bytes)]")
} catch {
    fputs("cotty smoke failed: \(error)\n", stderr)
    exit(1)
}
