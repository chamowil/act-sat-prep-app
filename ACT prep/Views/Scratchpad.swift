//
//  Scratchpad.swift
//  ACT prep
//
//  A PencilKit scratch surface for working problems by hand, the way you would
//  on the scratch paper the real test gives you. Drawings are saved per
//  question, so leaving a question and coming back keeps your work.
//

import SwiftUI
import PencilKit

// MARK: - Storage

/// Persists one PKDrawing per key (usually a question id) as a single JSON
/// file of base64 blobs.
final class ScratchpadStore {
    static let shared = ScratchpadStore()

    private let url: URL
    private var drawings: [String: Data]

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("scratchpads.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: Data].self, from: data) {
            drawings = decoded
        } else {
            drawings = [:]
        }
    }

    func drawing(for key: String) -> PKDrawing {
        guard let data = drawings[key], let drawing = try? PKDrawing(data: data) else {
            return PKDrawing()
        }
        return drawing
    }

    func hasDrawing(for key: String) -> Bool {
        guard let data = drawings[key], let drawing = try? PKDrawing(data: data) else { return false }
        return !drawing.strokes.isEmpty
    }

    func save(_ drawing: PKDrawing, for key: String) {
        if drawing.strokes.isEmpty {
            drawings[key] = nil
        } else {
            drawings[key] = drawing.dataRepresentation()
        }
        persist()
    }

    func clear(_ key: String) {
        drawings[key] = nil
        persist()
    }

    func reset() {
        drawings = [:]
        try? FileManager.default.removeItem(at: url)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(drawings) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Canvas

/// Wraps `PKCanvasView`. Apple Pencil always draws; whether a finger draws or
/// scrolls follows the student's setting.
///
/// The canvas is pinned to a light appearance so it behaves like a real sheet
/// of scratch paper: dark ink on pale paper in either app theme. Without this,
/// a dynamic ink color resolves against whichever trait environment SwiftUI
/// happened to build the tool in, and strokes come out black on a dark canvas.
struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: PKTool
    var allowsFingerDrawing: Bool
    /// Handed back so the toolbar can drive undo and redo.
    var onCanvasReady: (PKCanvasView) -> Void = { _ in }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawing = drawing
        canvas.tool = tool
        canvas.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        canvas.accessibilityLabel = "Scratchpad canvas"
        DispatchQueue.main.async { onCanvasReady(canvas) }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.tool = tool
        canvas.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        // Only push the drawing back in when it genuinely differs, so typing
        // into the binding from a Clear doesn't fight live strokes.
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private let parent: PencilCanvas

        init(_ parent: PencilCanvas) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

/// Paper colors, fixed in both themes so ink always reads the same.
enum Paper {
    /// Warm off-white — easier on the eyes at night than pure white.
    static let sheet = Color(red: 0.980, green: 0.976, blue: 0.965)
    static let grid = Color(red: 0.792, green: 0.800, blue: 0.816)
}

/// Faint graph-paper grid behind the canvas — useful for sketching lines,
/// triangles, and coordinate planes.
struct GraphPaper: View {
    var spacing: CGFloat = 24

    var body: some View {
        Canvas { context, size in
            let line = Paper.grid.opacity(0.75)
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(path, with: .color(line), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Scratchpad sheet

struct ScratchpadView: View {
    /// Key the drawing is stored under, normally the question id.
    let key: String
    /// Shown at the top so you can keep the question in view while working.
    var contextText: String?

    @Environment(\.dismiss) private var dismiss
    @State private var settings = UserSettings.shared
    @State private var drawing = PKDrawing()
    @State private var canvas: PKCanvasView?
    @State private var selectedTool: ToolKind = .pen
    @State private var selectedColor: InkColor = .ink
    @State private var showGrid = true
    @State private var showClearAlert = false

    enum ToolKind: String, CaseIterable, Identifiable {
        case pen, pencil, marker, eraser
        var id: String { rawValue }

        var symbolName: String {
            switch self {
            case .pen: return "pencil.tip"
            case .pencil: return "pencil"
            case .marker: return "highlighter"
            case .eraser: return "eraser"
            }
        }

        var title: String {
            switch self {
            case .pen: return "Pen"
            case .pencil: return "Pencil"
            case .marker: return "Highlighter"
            case .eraser: return "Eraser"
            }
        }
    }

    /// Fixed ink colors. These are deliberately not dynamic system colors — a
    /// stroke is saved with the color it was drawn in, so a color that changes
    /// with the theme would leave old work invisible later.
    enum InkColor: String, CaseIterable, Identifiable {
        case ink, blue, red, green
        var id: String { rawValue }

        var color: Color {
            switch self {
            case .ink: return Color(red: 0.106, green: 0.118, blue: 0.141)
            case .blue: return Color(red: 0.0, green: 0.353, blue: 0.804)
            case .red: return Color(red: 0.839, green: 0.145, blue: 0.145)
            case .green: return Color(red: 0.055, green: 0.478, blue: 0.286)
            }
        }

        var uiColor: UIColor { UIColor(color) }

        var title: String {
            switch self {
            case .ink: return "Black ink"
            case .blue: return "Blue"
            case .red: return "Red"
            case .green: return "Green"
            }
        }
    }

    private var tool: PKTool {
        switch selectedTool {
        case .pen:
            return PKInkingTool(.pen, color: selectedColor.uiColor, width: 5)
        case .pencil:
            return PKInkingTool(.pencil, color: selectedColor.uiColor, width: 4)
        case .marker:
            return PKInkingTool(.marker, color: selectedColor.uiColor.withAlphaComponent(0.4), width: 22)
        case .eraser:
            return PKEraserTool(.bitmap)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let contextText, !contextText.isEmpty {
                    ScrollView {
                        Text(contextText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                    }
                    .frame(maxHeight: 110)
                    .background(Color.appSecondaryBackground)
                    Divider()
                }

                canvasArea
                Divider()
                toolbar
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Scratchpad")
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { save(); dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Toggle("Graph paper", isOn: $showGrid)
                        Toggle("Draw with finger", isOn: Binding(
                            get: { settings.allowsFingerDrawing },
                            set: { settings.allowsFingerDrawing = $0 }
                        ))
                        Divider()
                        Button(role: .destructive) {
                            showClearAlert = true
                        } label: {
                            Label("Clear page", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Scratchpad options")
                }
            }
            .alert("Clear this page?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) { clear() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your work on this question will be erased.")
            }
        }
        .onAppear { drawing = ScratchpadStore.shared.drawing(for: key) }
        .onDisappear { save() }
    }

    private var canvasArea: some View {
        ZStack {
            Paper.sheet
            if showGrid { GraphPaper() }
            PencilCanvas(
                drawing: $drawing,
                tool: tool,
                allowsFingerDrawing: settings.allowsFingerDrawing
            ) { canvas = $0 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(ToolKind.allCases) { kind in
                    Button {
                        selectedTool = kind
                    } label: {
                        Image(systemName: kind.symbolName)
                            .font(.system(size: 17))
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(
                                selectedTool == kind
                                    ? Color.accentColor.opacity(0.18) : Color.appFill,
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                            .foregroundStyle(selectedTool == kind ? Color.accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(kind.title)
                    .accessibilityAddTraits(selectedTool == kind ? .isSelected : [])
                }
            }

            HStack(spacing: 12) {
                // The swatches sit on a paper-colored pill so the dark ink
                // stays visible when the app itself is in dark mode.
                HStack(spacing: 12) {
                    ForEach(InkColor.allCases) { ink in
                        Button {
                            selectedColor = ink
                            if selectedTool == .eraser { selectedTool = .pen }
                        } label: {
                            Circle()
                                .fill(ink.color)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle().stroke(
                                        selectedColor == ink ? Color.accentColor : Paper.grid,
                                        lineWidth: selectedColor == ink ? 3 : 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(ink.title)
                        .accessibilityAddTraits(selectedColor == ink ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Paper.sheet, in: Capsule())

                Spacer()

                Button {
                    canvas?.undoManager?.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(canvas?.undoManager?.canUndo != true)
                .accessibilityLabel("Undo")

                Button {
                    canvas?.undoManager?.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(canvas?.undoManager?.canRedo != true)
                .accessibilityLabel("Redo")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func save() {
        ScratchpadStore.shared.save(drawing, for: key)
    }

    private func clear() {
        drawing = PKDrawing()
        canvas?.drawing = PKDrawing()
        ScratchpadStore.shared.clear(key)
    }
}

// MARK: - Entry point button

/// Toolbar button that opens the scratchpad for one question and shows a dot
/// when that question already has work on it.
struct ScratchpadButton: View {
    let key: String
    var contextText: String?
    var compact: Bool = false

    @State private var isPresented = false
    @State private var hasWork = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Label("Scratchpad", systemImage: "pencil.and.scribble")
                    .labelStyle(compact ? AnyLabelStyle(.iconOnly) : AnyLabelStyle(.titleAndIcon))
                if hasWork {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 7, height: 7)
                        .offset(x: 3, y: -2)
                }
            }
        }
        .accessibilityLabel(hasWork ? "Scratchpad, has notes" : "Scratchpad")
        .sheet(isPresented: $isPresented) {
            ScratchpadView(key: key, contextText: contextText)
        }
        .onAppear { hasWork = ScratchpadStore.shared.hasDrawing(for: key) }
        .onChange(of: isPresented) { _, showing in
            if !showing { hasWork = ScratchpadStore.shared.hasDrawing(for: key) }
        }
        .onChange(of: key) { _, newKey in
            hasWork = ScratchpadStore.shared.hasDrawing(for: newKey)
        }
    }
}

/// Lets a label style be chosen at runtime.
struct AnyLabelStyle: LabelStyle {
    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: LabelStyle>(_ style: S) {
        makeBodyClosure = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}
