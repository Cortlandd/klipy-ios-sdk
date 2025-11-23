////
////  KlipyGridView.swift
////  KlipySDK
////
////  Created by Cortland Walker on 11/21/25.
////
//
//import SwiftUI
//import KlipyCore
//
///// Simple grid view for displaying Klipy media.
///// You can later swap this for a masonry-style layout if you want.
//@available(iOS 14.0, *)
//public struct KlipyGridView: View {
//    public let items: [KlipyMedia]
//    public let onSelect: (KlipyMedia) -> Void
//
//    public init(
//        items: [KlipyMedia],
//        onSelect: @escaping (KlipyMedia) -> Void
//    ) {
//        self.items = items
//        self.onSelect = onSelect
//    }
//
//    private let columns = [
//        GridItem(.adaptive(minimum: 100), spacing: 8)
//    ]
//
//    public var body: some View {
//        ScrollView {
//            LazyVGrid(columns: columns, spacing: 8) {
//                ForEach(items) { media in
//                    KlipyThumbnailView(media: media)
//                        .onTapGesture {
//                            onSelect(media)
//                        }
//                }
//            }
//            .padding(8)
//        }
//    }
//}
//
///// Basic thumbnail for a Klipy media item.
//@available(iOS 14.0, *)
//public struct KlipyThumbnailView: View {
//    public let media: KlipyMedia
//
//    public init(media: KlipyMedia) {
//        self.media = media
//    }
//
//    public var body: some View {
//        AsyncImage(url: media.previewURL ?? media.gifURL) { phase in
//            switch phase {
//            case .empty:
//                Color.gray.opacity(0.2)
//                    .overlay(
//                        ProgressView().progressViewStyle(.circular)
//                    )
//            case .success(let image):
//                image
//                    .resizable()
//                    .scaledToFill()
//            case .failure:
//                Color.red.opacity(0.2)
//                    .overlay(
//                        Image(systemName: "xmark.octagon")
//                            .foregroundStyle(.white)
//                    )
//            @unknown default:
//                Color.gray.opacity(0.2)
//            }
//        }
//        .frame(height: 120)
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//        .clipped()
//    }
//}
