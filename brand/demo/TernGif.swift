import AppKit
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import AVFoundation
import CoreVideo

// Cena: 1600x900 lógicos, exportada em 1200x675 (16:9, bom para X/LinkedIn).
let W: CGFloat = 1600, H: CGFloat = 900
let duration = 7.2

let night = Color(red: 0x1A/255, green: 0x21/255, blue: 0x33/255)
let slate = Color(red: 0x2E/255, green: 0x3D/255, blue: 0x5E/255)
let sky = Color(red: 0x4A/255, green: 0x8B/255, blue: 0xE8/255)
let mist = Color(red: 0xE8/255, green: 0xEE/255, blue: 0xFC/255)
let coral = Color(red: 0xF2/255, green: 0x70/255, blue: 0x5F/255)

struct Strings {
    let count: (Int) -> String
    let switchCaption, hideCaption, focusCaption, hiddenToast, footer, clock: String
    static let en = Strings(
        count: { "\($0) windows" },
        switchCaption: "⌥⇥  switch windows, not just apps",
        hideCaption: "⌫  hide an app you never switch to",
        focusCaption: "Let go to focus",
        hiddenToast: "Messages hidden from Tern",
        footer: "⇥ next   ⇧⇥ previous   ⌫ hide app   ⌥⌫ just this window   ⏎ open   esc close",
        clock: "Fri 3:02 PM")
    static let pt = Strings(
        count: { "\($0) janelas" },
        switchCaption: "⌥⇥  troca de janela, não só de app",
        hideCaption: "⌫  esconde o app que só atrapalha",
        focusCaption: "Solte para focar",
        hiddenToast: "Mensagens oculto no Tern",
        footer: "⇥ próximo   ⇧⇥ anterior   ⌫ ocultar app   ⌥⌫ só esta janela   ⏎ abrir   esc fechar",
        clock: "sex. 15:02")
}

enum Kind { case browser, code, chat, notes, terminal }

struct Win: Identifiable {
    let id: String
    let app: String
    let title: String
    let icon: NSImage
    let kind: Kind
}

func icon(_ path: String) -> NSImage {
    let img = NSWorkspace.shared.icon(forFile: path)
    img.size = NSSize(width: 128, height: 128)
    return img
}

func windows(_ pt: Bool) -> [Win] {
    [
        Win(id: "xcode", app: "Xcode", title: "Tern — SwitcherView.swift", icon: icon("/Applications/Xcode.app"), kind: .code),
        Win(id: "safari", app: "Safari", title: pt ? "Tern — seletor de janelas" : "Tern — window switcher", icon: icon("/Applications/Safari.app"), kind: .browser),
        Win(id: "messages", app: pt ? "Mensagens" : "Messages", title: pt ? "Grupo da faculdade" : "Group chat", icon: icon("/System/Applications/Messages.app"), kind: .chat),
        Win(id: "notes", app: pt ? "Notas" : "Notes", title: pt ? "Post de lançamento" : "Launch post", icon: icon("/System/Applications/Notes.app"), kind: .notes),
        Win(id: "terminal", app: "Terminal", title: "~/www/tern — zsh", icon: icon("/System/Applications/Utilities/Terminal.app"), kind: .terminal),
    ]
}

// MARK: - Window content stand-ins

struct Bars: View {
    let color: Color
    let widths: [CGFloat]
    var height: CGFloat = 7
    var spacing: CGFloat = 7
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(widths.enumerated()), id: \.offset) { _, w in
                RoundedRectangle(cornerRadius: height / 2).fill(color).frame(width: w, height: height)
            }
        }
    }
}

struct WindowContent: View {
    let kind: Kind
    let scale: CGFloat
    var body: some View {
        switch kind {
        case .browser:
            VStack(spacing: 0) {
                Rectangle().fill(Color(white: 0.9)).frame(height: 18 * scale)
                ZStack(alignment: .topLeading) {
                    night
                    VStack(alignment: .leading, spacing: 8 * scale) {
                        RoundedRectangle(cornerRadius: 3 * scale).fill(mist).frame(width: 90 * scale, height: 12 * scale)
                        RoundedRectangle(cornerRadius: 3 * scale).fill(sky).frame(width: 60 * scale, height: 12 * scale)
                        Capsule().fill(sky).frame(width: 46 * scale, height: 12 * scale).padding(.top, 4 * scale)
                    }
                    .padding(14 * scale)
                }
            }
        case .code:
            ZStack(alignment: .topLeading) {
                Color(red: 0.12, green: 0.12, blue: 0.14)
                HStack(alignment: .top, spacing: 10 * scale) {
                    Rectangle().fill(Color(white: 0.17)).frame(width: 34 * scale)
                    VStack(alignment: .leading, spacing: 6 * scale) {
                        Bars(color: Color(red: 0.98, green: 0.45, blue: 0.62), widths: [50 * scale], height: 5 * scale)
                        Bars(color: Color(red: 0.55, green: 0.82, blue: 0.98), widths: [90 * scale, 70 * scale], height: 5 * scale, spacing: 6 * scale)
                        Bars(color: Color(white: 0.6), widths: [110 * scale, 60 * scale, 84 * scale], height: 5 * scale, spacing: 6 * scale)
                        Bars(color: Color(red: 0.99, green: 0.75, blue: 0.45), widths: [40 * scale], height: 5 * scale)
                    }
                    .padding(.top, 10 * scale)
                }
            }
        case .chat:
            ZStack {
                Color.white
                VStack(spacing: 7 * scale) {
                    HStack { Capsule().fill(Color(white: 0.9)).frame(width: 80 * scale, height: 16 * scale); Spacer() }
                    HStack { Spacer(); Capsule().fill(Color(red: 0.2, green: 0.5, blue: 1)).frame(width: 64 * scale, height: 16 * scale) }
                    HStack { Capsule().fill(Color(white: 0.9)).frame(width: 96 * scale, height: 16 * scale); Spacer() }
                }
                .padding(12 * scale)
            }
        case .notes:
            ZStack(alignment: .topLeading) {
                Color(red: 1, green: 0.98, blue: 0.9)
                VStack(alignment: .leading, spacing: 8 * scale) {
                    RoundedRectangle(cornerRadius: 3 * scale).fill(Color(white: 0.2)).frame(width: 84 * scale, height: 10 * scale)
                    Bars(color: Color(white: 0.75), widths: [140 * scale, 120 * scale, 132 * scale, 70 * scale], height: 5 * scale, spacing: 7 * scale)
                }
                .padding(14 * scale)
            }
        case .terminal:
            ZStack(alignment: .topLeading) {
                Color(red: 0.08, green: 0.08, blue: 0.09)
                VStack(alignment: .leading, spacing: 6 * scale) {
                    Bars(color: Color(red: 0.4, green: 0.85, blue: 0.5), widths: [70 * scale], height: 5 * scale)
                    Bars(color: Color(white: 0.55), widths: [130 * scale, 100 * scale, 116 * scale], height: 5 * scale, spacing: 6 * scale)
                    Bars(color: Color(red: 0.4, green: 0.85, blue: 0.5), widths: [40 * scale], height: 5 * scale)
                }
                .padding(12 * scale)
            }
        }
    }
}

// MARK: - Switcher (mirrors SwitcherView / WindowCard)

struct Card: View {
    let win: Win
    let selected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                WindowContent(kind: win.kind, scale: 1)
                    .frame(width: 208, height: 124)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Image(nsImage: win.icon)
                    .resizable().interpolation(.high)
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                    .padding(6)
            }
            Text(win.title)
                .font(.system(size: 13, weight: selected ? .semibold : .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(height: 34, alignment: .topLeading)
            Text(win.app)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(10)
        .frame(width: 228, height: 228)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(selected ? sky.opacity(0.24) : Color.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(selected ? sky : Color.white.opacity(0.08), lineWidth: selected ? 2.5 : 1))
        .scaleEffect(selected ? 1.03 : 1)
    }
}

struct MenuBarGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 18
            var back = Path()
            back.move(to: CGPoint(x: 4.5 * s, y: 10.5 * s))
            back.addLine(to: CGPoint(x: 3.5 * s, y: 10.5 * s))
            back.addArc(tangent1End: CGPoint(x: 1.5 * s, y: 10.5 * s), tangent2End: CGPoint(x: 1.5 * s, y: 2.5 * s), radius: 2 * s)
            back.addArc(tangent1End: CGPoint(x: 1.5 * s, y: 2.5 * s), tangent2End: CGPoint(x: 11.5 * s, y: 2.5 * s), radius: 2 * s)
            back.addArc(tangent1End: CGPoint(x: 11.5 * s, y: 2.5 * s), tangent2End: CGPoint(x: 11.5 * s, y: 10.5 * s), radius: 2 * s)
            back.addLine(to: CGPoint(x: 11.5 * s, y: 5.5 * s))
            ctx.stroke(back, with: .foreground, style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
            ctx.fill(Path(roundedRect: CGRect(x: 6 * s, y: 7 * s, width: 10.5 * s, height: 8.5 * s), cornerRadius: 2 * s), with: .foreground)
        }
    }
}

struct HUD: View {
    let wins: [Win]
    let hidingID: String?
    let hideProgress: Double
    let selectedID: String
    let strings: Strings
    let toast: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                MenuBarGlyph().frame(width: 18, height: 18).foregroundStyle(sky)
                Text(verbatim: "Tern").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                let count = wins.count - (hidingID != nil && hideProgress >= 1 ? 1 : 0)
                Text(strings.count(count)).font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
            }
            HStack(spacing: 12) {
                ForEach(wins) { w in
                    let hiding = w.id == hidingID
                    let p = hiding ? hideProgress : 0
                    Card(win: w, selected: w.id == selectedID && !hiding)
                        .scaleEffect(1 - 0.25 * p)
                        .opacity(max(0, 1 - 2.2 * p))
                        .frame(width: 228 * (1 - p))
                        .padding(.trailing, hiding ? -12 * p : 0)
                }
            }
            .padding(.vertical, 4)
            HStack(spacing: 8) {
                if toast {
                    Circle().fill(coral).frame(width: 16, height: 16)
                        .overlay(Capsule().fill(.white).frame(width: 9, height: 2.5).rotationEffect(.degrees(40)))
                    Text(strings.hiddenToast).font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
                } else {
                    Text(strings.footer).font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(height: 18)
        }
        .padding(18)
        .fixedSize()
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(red: 0.13, green: 0.15, blue: 0.21).opacity(0.94)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 30, y: 16)
    }
}

// MARK: - Desktop

struct AppWindow: View {
    let win: Win
    let size: CGSize
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(white: 0.93)
                HStack(spacing: 7) {
                    Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 12, height: 12)
                    Circle().fill(Color(red: 1, green: 0.74, blue: 0.18)).frame(width: 12, height: 12)
                    Circle().fill(Color(red: 0.16, green: 0.79, blue: 0.25)).frame(width: 12, height: 12)
                    Spacer()
                }
                .padding(.horizontal, 14)
                Text(win.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(white: 0.3))
            }
            .frame(height: 34)
            WindowContent(kind: win.kind, scale: size.width / 208 * 0.62)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.black.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
    }
}

struct Keycap: View {
    let label: String
    let pressed: Bool
    let wide: Bool
    var body: some View {
        Text(label)
            .font(.system(size: 26, weight: .medium))
            .foregroundStyle(pressed ? .white : night)
            .frame(width: wide ? 92 : 64, height: 64)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(pressed ? sky : mist))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.black.opacity(0.15), lineWidth: 1))
            .offset(y: pressed ? 3 : 0)
            .shadow(color: .black.opacity(pressed ? 0.15 : 0.35), radius: pressed ? 2 : 6, y: pressed ? 1 : 5)
    }
}

struct SceneView: View {
    let t: Double
    let strings: Strings
    let wins: [Win]

    // Linha do tempo (segundos)
    let open = 0.9, tab2 = 1.9, del = 3.1, release = 4.5, end = 7.2

    func pulse(_ at: Double, _ len: Double = 0.22) -> Bool { t >= at && t < at + len }

    var body: some View {
        let hudOn = t >= open && t < release
        let hideP = min(max((t - del - 0.15) / 0.35, 0), 1)
        let selected: String = t < tab2 ? "safari" : (t < del + 0.15 ? "messages" : "notes")
        let frontID = t < release ? "xcode" : "notes"
        let front = wins.first { $0.id == frontID }!
        let back = wins.first { $0.id == (frontID == "xcode" ? "safari" : "xcode") }!
        let caption: String? = t < open ? nil : (t < del ? strings.switchCaption : (t < release ? strings.hideCaption : strings.focusCaption))

        ZStack {
            night
            // Fundo: duas manchas suaves para dar profundidade
            Circle().fill(slate.opacity(0.55)).frame(width: 900).offset(x: -520, y: -260)
            Circle().fill(sky.opacity(0.10)).frame(width: 700).offset(x: 560, y: 300)

            // Barra de menus
            VStack {
                HStack(spacing: 22) {
                    Text(front.app).font(.system(size: 14, weight: .bold))
                    Spacer()
                    MenuBarGlyph().frame(width: 18, height: 18)
                    Image(systemName: "wifi").font(.system(size: 14, weight: .semibold))
                    Text(strings.clock).font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 34)
                .background(Color.black.opacity(0.35))
                Spacer()
            }

            AppWindow(win: back, size: CGSize(width: 760, height: 470)).offset(x: 230, y: 40)
            AppWindow(win: front, size: CGSize(width: 860, height: 530)).offset(x: -170, y: 10)

            if hudOn || (t >= release && t < release + 0.12) {
                HUD(wins: wins, hidingID: t >= del ? "messages" : nil, hideProgress: hideP,
                    selectedID: selected, strings: strings, toast: t >= del + 0.2)
                    .opacity(t < open + 0.12 ? (t - open) / 0.12 : (t >= release ? 1 - (t - release) / 0.12 : 1))
                    .offset(y: -40)
            }

            // Teclas + legenda
            VStack(spacing: 18) {
                Spacer()
                if let caption {
                    Text(caption)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26).padding(.vertical, 12)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                }
                HStack(spacing: 14) {
                    Keycap(label: "⌥", pressed: t >= open && t < release, wide: true)
                    Keycap(label: "⇥", pressed: pulse(open) || pulse(tab2), wide: true)
                    Keycap(label: "⌫", pressed: pulse(del), wide: true)
                }
                .opacity(t < open - 0.3 ? 0.55 : 1)
            }
            .padding(.bottom, 48)

            // Marca
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Spacer()
                    MenuBarGlyph().frame(width: 22, height: 22).foregroundStyle(sky)
                    Text(verbatim: "tern.gitlher.me").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                }
                .padding(28)
            }
        }
        .frame(width: W, height: H)
        .clipped()
        .environment(\.colorScheme, .dark)
    }
}

func toSRGB(_ img: CGImage) -> CGImage {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
    return ctx.makeImage()!
}

@MainActor
func render(lang: String, to url: URL, fps: Double = 12) {
    let strings = lang == "pt" ? Strings.pt : Strings.en
    let wins = windows(lang == "pt")
    let frames = Int(duration * fps)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames, nil) else { fatalError("dest") }
    CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    for i in 0..<frames {
        let t = Double(i) / fps
        let renderer = ImageRenderer(content: SceneView(t: t, strings: strings, wins: wins))
        renderer.scale = 0.75
        renderer.isOpaque = true
        guard let raw = renderer.cgImage else { fatalError("frame \(i)") }
        let cg = toSRGB(raw)
        let props = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / fps, kCGImagePropertyGIFUnclampedDelayTime: 1.0 / fps]] as CFDictionary
        CGImageDestinationAddImage(dest, cg, props)
        if false, i == Int(3.9 * fps) {
            // Quadro-chave em PNG para conferir
            let png = url.deletingPathExtension().appendingPathExtension("png")
            if let d = CGImageDestinationCreateWithURL(png as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(d, cg, nil); CGImageDestinationFinalize(d)
            }
        }
    }
    guard CGImageDestinationFinalize(dest) else { fatalError("finalize") }
}


@MainActor
func renderMP4(lang: String, to url: URL, fps: Int32 = 30) {
    let strings = lang == "pt" ? Strings.pt : Strings.en
    let wins = windows(lang == "pt")
    try? FileManager.default.removeItem(at: url)
    let w = Int(W * 0.75), h = Int(H * 0.75)
    let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: w, AVVideoHeightKey: h,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 4_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
        AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                                    AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                                    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2]])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: w, kCVPixelBufferHeightKey as String: h])
    writer.add(input)
    writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let frames = Int(duration * Double(fps))
    for i in 0..<frames {
        let t = Double(i) / Double(fps)
        let r = ImageRenderer(content: SceneView(t: t, strings: strings, wins: wins))
        r.scale = 0.75; r.isOpaque = true
        let cg = toSRGB(r.cgImage!)
        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
        let buf = pb!
        CVPixelBufferLockBaseAddress(buf, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: w, height: h, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buf), space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        CVPixelBufferUnlockBaseAddress(buf, [])
        while !input.isReadyForMoreMediaData { usleep(1000) }
        adaptor.append(buf, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    while done.wait(timeout: .now()) == .timedOut { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
    if writer.status != .completed { fatalError("mp4: \(String(describing: writer.error))") }
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let langs = CommandLine.arguments.count > 2 ? Array(CommandLine.arguments[2...]) : ["en", "pt"]
MainActor.assumeIsolated {
    for lang in langs {
        let gif = outDir.appendingPathComponent("tern-demo-\(lang).gif")
        render(lang: lang, to: gif)
        let mp4 = outDir.appendingPathComponent("tern-demo-\(lang).mp4")
        renderMP4(lang: lang, to: mp4)
        print("ok", lang)
    }
}
