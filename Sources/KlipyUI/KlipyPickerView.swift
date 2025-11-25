//
//  KlipyPickerView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import SwiftUI
import KlipyCore
import SDWebImageSwiftUI

public struct KlipyPickerView: View {
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel: KlipyPickerViewModel
    private let onSelect: (KlipyMedia) -> Void
    private let onClose: (() -> Void)?
    
    // Global mute state for clips in this picker
    @State private var isClipsMuted: Bool = true

    public init(
        client: KlipyClient,
        initialTab: KlipyPickerMediaTab = .gifs,
        onSelect: @escaping (KlipyMedia) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: KlipyPickerViewModel(
                client: client,
                initialTab: initialTab
            )
        )
        KlipyUIBootstrap.configureIfNeeded()
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            topHandleBar

            // Main content
            VStack(spacing: 8) {
                tabSelector
                searchField
                content
            }
            .padding(.horizontal, 8)

            poweredByBar
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
        .onAppear {
            viewModel.loadInitial()
        }
    }

    // MARK: - Top handle

    private var topHandleBar: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.vertical, 6)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onClose?()
        }
        .accessibilityLabel("Close Klipy picker")
    }

    // MARK: - Bottom "Powered by Klipy"

    private var poweredByBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray)
            Button {
                if let url = URL(string: "https://klipy.com/en-US") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(.klipyLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("Powered by Klipy")
                        .font(.footnote.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .background(Color.white)
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .accessibilityLabel("Open Klipy website")
        }
    }

    // MARK: - Tabs

    private var tabSelector: some View {
        Picker("Type", selection: $viewModel.selectedTab) {
            ForEach(KlipyPickerMediaTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedTab) { newValue in
            viewModel.didChangeTab(newValue)
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack {
            TextField("Search", text: $viewModel.query, onCommit: {
                viewModel.submitSearch()
            })
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                HStack {
                    Spacer()
                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                            viewModel.loadInitial()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            )
        }
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.lastError {
                VStack(spacing: 8) {
                    Text("Failed to load Klipy content.")
                        .font(.callout)
                    Text(error.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.loadInitial()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                scrollGrid
            }
        }
    }

    // Two-column, variable-height grid like Giphy
    private var gridColumns: [GridItem] {
        return [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ]
    }

    private var scrollGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 4) {
                ForEach(viewModel.items, id: \.id) { media in
                    Button {
                        onSelect(media)
                    } label: {
                        KlipyThumbnailView(media: media, isClipsMuted: $isClipsMuted)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        viewModel.loadMoreIfNeeded(currentItem: media)
                    }
                }

                if viewModel.isLoading && !viewModel.items.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Thumbnail tile

struct KlipyThumbnailView: View {
    let media: KlipyMedia
    @Binding var isClipsMuted: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))

            if let url = media.previewURL {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(media.displayAspectRatio, contentMode: .fill)
                    .clipped()
                    .cornerRadius(10)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }

            if media.type == .clip {
                Button {
                    isClipsMuted.toggle()
                } label: {
                    Image(systemName: isClipsMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(6)
                .buttonStyle(.plain)
            }
        }
        .aspectRatio(media.displayAspectRatio, contentMode: .fit)
    }
}

#if DEBUG
import SwiftUI
import KlipyCore
@available(iOS 14.0, *)
struct KlipyPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // For now we just use a live client with a fake key.
        // In the preview canvas this will typically just show the loading state
        // (or real content if you plug in a valid key).
        let client = KlipyClient.live(apiKey: "DEMO_PREVIEW_KEY")

        KlipyPickerView(
            client: client,
            initialTab: .gifs,
            onSelect: { media in
                print(media)
            },
            onClose: {
                print("close")
            }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
