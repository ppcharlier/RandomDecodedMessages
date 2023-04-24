//
//  AttributedText.swift
//  RandomDecodedMessages
//
//  Created by Pierre-Philippe Charlier on 24/04/2023.
//

import SwiftUI


struct AttributedText: UIViewRepresentable {
    var attributedString: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
    }
}
