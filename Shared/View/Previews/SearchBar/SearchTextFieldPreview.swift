//import SwiftUI
//
//#Preview("SearchTextField - Default") {
//    @Previewable @State var text = "Sample text"
//    @Previewable @FocusState var isFocused: Bool
//
//    ZStack {
//        Color.black.opacity(0.8)
//
//        SearchTextField(
//            text: $text,
//            isFocused: $isFocused,
//            fontSize: 16,
//            alignment: .topLeading,
//            verticalPadding: 8,
//            trailingPadding: 0,
//            onTab: {},
//            onShiftReturn: {},
//            onResetTabState: {}
//        )
//    }
//    .frame(width: 300, height: 100)
//    .onAppear { isFocused = true }
//}
//
//#Preview("SearchTextField - Empty") {
//    @Previewable @State var text = ""
//    @Previewable @FocusState var isFocused: Bool
//
//    ZStack {
//        Color.black.opacity(0.8)
//
//        SearchTextField(
//            text: $text,
//            isFocused: $isFocused,
//            fontSize: 16,
//            alignment: .topLeading,
//            verticalPadding: 8,
//            trailingPadding: 0,
//            onTab: {},
//            onShiftReturn: {},
//            onResetTabState: {}
//        )
//    }
//    .frame(width: 300, height: 100)
//    .onAppear { isFocused = true }
//}
//
//#Preview("SearchTextField - Multiline") {
//    @Previewable @State var text = "This is a longer text\nthat spans multiple lines\nto test the multiline behavior"
//    @Previewable @FocusState var isFocused: Bool
//
//    ZStack {
//        Color.black.opacity(0.8)
//
//        SearchTextField(
//            text: $text,
//            isFocused: $isFocused,
//            fontSize: 16,
//            alignment: .topLeading,
//            verticalPadding: 8,
//            trailingPadding: 48,
//            onTab: {},
//            onShiftReturn: {},
//            onResetTabState: {}
//        )
//    }
//    .frame(width: 400, height: 200)
//    .onAppear { isFocused = true }
//}
