//
//  SyncStatusView.swift
//  frindr
//
//  Sync status indicator overlay
//

import SwiftUI

struct SyncStatusView: View {
    @Environment(SyncManager.self) private var syncManager

    var body: some View {
        Group {
            switch syncManager.status {
            case .syncing:
                syncingIndicator
            case .offline:
                offlineIndicator
            case .error(let message):
                errorIndicator(message: message)
            case .idle:
                if syncManager.pendingMutationCount > 0 {
                    pendingIndicator
                }
            }
        }
    }

    private var syncingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.7)

            Text("Syncing...")
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }

    private var offlineIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundStyle(.orange)

            Text("Offline")
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }

    private func errorIndicator(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)

            Text("Sync error")
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }

    private var pendingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.yellow)

            Text("\(syncManager.pendingMutationCount) pending")
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }
}
