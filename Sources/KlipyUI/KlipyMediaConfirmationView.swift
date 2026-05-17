//
//  KlipyMediaConfirmationView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 5/16/26.
//

import SwiftUI
import KlipyCore

struct KlipyMediaConfirmationView: View {
    let media: KlipyMedia
    let theme: KlipyTheme
    let onSelect: () -> Void
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: KlipyThemePalette {
        theme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                KlipyMediaPreviewView(media: media)
                    .frame(maxHeight: 320)

                VStack(spacing: 8) {
                    Text(media.title ?? media.slug)
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text("Review the selected media before sending it.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)

                Button(action: onSelect) {
                    Text("Send")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            .padding(.top, 20)
            .navigationTitle("Confirm Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
            .background(containerBackground)
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        if palette.chromeMaterial != nil {
            Rectangle()
                .fill(palette.chromeMaterial ?? .regularMaterial)
                .ignoresSafeArea()
        } else {
            palette.surface
                .ignoresSafeArea()
        }
    }
}
