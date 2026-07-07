import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager
    @State private var showFullDiskAccessPrompt = false

    var body: some View {
        NavigationSplitView {
            TagSidebarView()
        } detail: {
            FileListView()
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            TagPaletteController.shared.configure(appState: appState, language: language)
            appState.refreshTags()
        }
        .alert(
            language.localized("Could not update tags"),
            isPresented: Binding(
                get: { appState.tagEditError != nil },
                set: { if !$0 { appState.tagEditError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.tagEditError ?? "")
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
