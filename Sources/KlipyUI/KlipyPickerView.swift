//
//  KlipyPickerView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 11/21/25.
//

import SwiftUI
import KlipyCore

public struct KlipyPickerView: View {
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel: KlipyPickerViewModel
    private let onSelect: (KlipyMedia) -> Void
    private let onClose: (() -> Void)?

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

            poweredByBar
        }
        .padding(.top, 4)
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
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .accessibilityLabel("Open Klipy website")
    }

    // MARK: - Existing pieces (unchanged behavior)

    private var tabSelector: some View {
        // Either your segmented control or pill row:
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

    private var scrollGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3),
                spacing: 4
            ) {
                ForEach(viewModel.items, id: \.id) { media in
                    KlipyMediaTile(media: media)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentItem: media)
                        }
                        .onTapGesture {
                            onSelect(media)
                        }
                }
            }

            if viewModel.isLoading && !viewModel.items.isEmpty {
                ProgressView()
                    .padding(.vertical, 8)
            }
        }
    }
}


struct KlipyMediaTile: View {
    let media: KlipyMedia

    private var previewURL: URL? {
        media.file?.xs?.webp?.url ??
        media.file?.xs?.gif?.url ??
        media.file?.sm?.webp?.url ??
        media.file?.sm?.gif?.url ??
        media.file?.md?.webp?.url ??
        media.file?.md?.gif?.url
    }

    var body: some View {
        ZStack {
            if let url = previewURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.secondary.opacity(0.1)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Color.secondary.opacity(0.2)
                    @unknown default:
                        Color.secondary.opacity(0.1)
                    }
                }
            } else {
                Color.secondary.opacity(0.1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
