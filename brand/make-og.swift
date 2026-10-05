#!/usr/bin/env swift
// Gera site/og/pt.png e site/og/en.png (1200×630) a partir de brand/tern-icon.svg.
// Precisa dos TTF do Manrope em /tmp (SIL OFL):
//   curl -fsSL -o /tmp/manrope-bold.ttf https://raw.githubusercontent.com/googlefonts/manrope/master/fonts/ttf/manrope-bold.ttf
//   curl -fsSL -o /tmp/manrope-semibold.ttf https://raw.githubusercontent.com/googlefonts/manrope/master/fonts/ttf/manrope-semibold.ttf
// Uso: swift brand/make-og.swift /caminho/do/repo
import AppKit
import CoreText
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconURL = root.appendingPathComponent("brand/tern-icon.svg")
let boldURL = URL(fileURLWithPath: "/tmp/manrope-bold.ttf")
let semiURL = URL(fileURLWithPath: "/tmp/manrope-semibold.ttf")
let outDir = root.appendingPathComponent("site/og")

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

CTFontManagerRegisterFontsForURL(boldURL as CFURL, .process, nil)
CTFontManagerRegisterFontsForURL(semiURL as CFURL, .process, nil)

guard let icon = NSImage(contentsOf: iconURL) else {
    fputs("Não deu para abrir \(iconURL.path)\n", stderr)
    exit(1)
}

func srgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

func drawText(_ ctx: CGContext, _ string: String, font: CTFont, color: CGColor, centerX: CGFloat, baseline: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: color) ?? .white
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    ctx.textPosition = CGPoint(x: centerX - bounds.width / 2 - bounds.minX, y: baseline)
    CTLineDraw(line, ctx)
}

func render(tagline: String, dest: URL) {
    let width = 1200
    let height = 630
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { exit(1) }

    ctx.setFillColor(srgb(26, 33, 51))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

    let iconSide: CGFloat = 168
    let iconRect = CGRect(x: (CGFloat(width) - iconSide) / 2, y: 360, width: iconSide, height: iconSide)
    if let cgIcon = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        ctx.draw(cgIcon, in: iconRect)
    }

    let center = CGFloat(width) / 2
    let bold = CTFontCreateWithName("Manrope" as CFString, 72, nil)
    let semi = CTFontCreateWithName("Manrope" as CFString, 28, nil)
    let small = CTFontCreateWithName("Manrope" as CFString, 20, nil)

    drawText(ctx, "Tern", font: bold, color: srgb(232, 238, 252), centerX: center, baseline: 292)
    drawText(ctx, tagline, font: semi, color: srgb(74, 139, 232), centerX: center, baseline: 232)
    drawText(ctx, "tern.gitlher.me", font: small, color: srgb(163, 177, 204), centerX: center, baseline: 72)

    guard let cgImage = ctx.makeImage() else { exit(1) }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = NSSize(width: width, height: height)
    guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
    try! data.write(to: dest)
}

render(tagline: "Alt+Tab no Mac · alternador de janelas grátis", dest: outDir.appendingPathComponent("pt.png"))
render(tagline: "Alt-Tab for Mac · free window switcher", dest: outDir.appendingPathComponent("en.png"))
print("OG: \(outDir.path)")
