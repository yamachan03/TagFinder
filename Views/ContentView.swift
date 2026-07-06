import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showFullDiskAccessPrompt = false

    var body: some View {
        NavigationSplitView {
            TagSidebarView()
        } detail: {
            FileListView()
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            appState.refreshTags()
        }
        .onChange(of: appState.tagRepository.isLoading) { _, isLoading in
            guard !isLoading else { return }
            evaluateFullDiskAccess()
        }
        .sheet(isPresented: $showFullDiskAccessPrompt) {
            FullDiskAccessPromptView(isPresented: $showFullDiskAccessPrompt)
        }
    }

    private func evaluateFullDiskAccess() {
        let heuristicFailed = !FullDiskAccessChecker.canLikelyAccessProtectedFiles()
        let zeroResults = appState.tagRepository.lastGatherCount == 0
        showFullDiskAccessPrompt = heuristicFailed && zeroResults
    }
}
