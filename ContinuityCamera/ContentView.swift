//
//  ContentView.swift
//  ContinuityCamera
//
//  Created by Philipp on 21.04.21.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View, DropDelegate {
    
    @State private var image: NSImage?
    @State private var hovering = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Drag a document here")
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .strokeBorder(style: StrokeStyle(lineWidth: hovering ? 3 : 1))
                    )

                ContinuityCameraStartView(placeholder: "Right click here", image: $image)
                    .frame(width: 100, alignment: .center)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke()
                    )
            }
            .frame(maxHeight: 50, alignment: .center)

            Divider()

            if let image = self.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $hovering, perform: { (itemProviders, targetPosition) -> Bool in
            let urlIdentifier = UTType.fileURL.identifier
            for itemProvider in itemProviders {
                if itemProvider.hasItemConformingToTypeIdentifier(urlIdentifier) {
                    print(itemProvider.loadItem(forTypeIdentifier: urlIdentifier, options: nil, completionHandler: { (item, error) in
                        if let error = error {
                            print(error)
                        }
                        if let item = item,
                           let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil)
                        {
                            print(url)
                            if let nsImage = NSImage(contentsOf: url) {
                                DispatchQueue.main.async {
                                    self.image = nsImage
                                }
                            }
                        }
                    }))
                    return true
                }
            }
            return false
        })
        .frame(minWidth: 500, minHeight: 500)
        .padding()
    }

    func performDrop(info: DropInfo) -> Bool {
        print("performDrop: \(info)")
        if info.hasItemsConforming(to: [.image]) {
            
            return true
        }
        return false
    }
    
}

struct ContinuityCameraStartView: NSViewRepresentable {
    
    let placeholder: String
    @Binding var image: NSImage?

    typealias NSViewType = MyTextView
    
    func makeNSView(context: Context) -> MyTextView {
        let view = MyTextView()
        view.string = placeholder
        view.drawsBackground = false
        view.insertionPointColor = NSColor.textBackgroundColor
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.delegate = context.coordinator

        return view
    }
    
    func updateNSView(_ nsViewController: MyTextView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSServicesMenuRequestor {
        var parent: ContinuityCameraStartView

        init(_ parent: ContinuityCameraStartView) {
            self.parent = parent
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError()
        }
        
        func readSelection(from pasteboard: NSPasteboard) -> Bool {
            // Verify that the pasteboard contains image data.
            guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
                return false
            }
            // Load the image.
            guard let image = NSImage(pasteboard: pasteboard) else {
                return false
            }
            parent.image = image

            return true
        }

        func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // Return an empty context menu
            return NSMenu(title: menu.title)
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            // Ignore user selection
            NSMakeRange(0, 0)
        }
    }

    final class MyTextView: NSTextView {
        override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
            if let pasteboardType = returnType,
                // Service is image related.
                NSImage.imageTypes.contains(pasteboardType.rawValue) {
                return self.delegate
            } else {
                // Let objects in the responder chain handle the message.
                return super.validRequestor(forSendType: sendType, returnType: returnType)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
