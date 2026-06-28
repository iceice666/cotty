from pathlib import Path

path = Path("build.zig")
text = path.read_text()

text = text.replace(
    """    // macOS only artifacts. These will error if they're initialized for\n    // other targets.\n    if (config.target.result.os.tag.isDarwin()) {\n""",
    """    // macOS only artifacts. These will error if they're initialized for\n    // other targets. Skip unless requested so `zig build lib-vt` can build\n    // libghostty-vt by itself on Darwin.\n    if (config.target.result.os.tag.isDarwin() and (config.emit_xcframework or config.emit_macos_app)) {\n""",
)

text = text.replace(
    """        // On macOS we can run the macOS app. For "run" we always force\n        // a native-only build so that we can run as quickly as possible.\n        if (config.target.result.os.tag.isDarwin()) {\n""",
    """        // On macOS we can run the macOS app. For "run" we always force\n        // a native-only build so that we can run as quickly as possible.\n        if (config.target.result.os.tag.isDarwin() and config.emit_macos_app) {\n""",
)

path.write_text(text)
