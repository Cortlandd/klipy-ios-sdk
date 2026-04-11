//
//  KlipyOfflineStateView.swift
//  KlipySDK
//
//  Created by Cortland Walker on 4/11/26.
//

import SwiftUI

public struct KlipyOfflineStateView: View {
    private let title: String
    private let message: String
    private let actionTitle: String
    private let onRetry: () -> Void

    public init(
        title: String = "You're offline",
        message: String = "Connect to the internet and try again to load Klipy content.",
        actionTitle: String = "Try Again",
        onRetry: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.secondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(actionTitle, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
