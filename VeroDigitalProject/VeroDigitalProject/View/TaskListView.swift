//
//  TaskListView.swift
//  VeroDigitalProject
//
//  Created by Ivo Vasilski on 4.12.24.
//
import SwiftUI
import AVFoundation

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        if sanitized.count == 6, let hexInt = UInt64(sanitized, radix: 16) {
            self.init(
                .sRGB,
                red: Double((hexInt & 0xFF0000) >> 16) / 255.0,
                green: Double((hexInt & 0x00FF00) >> 8) / 255.0,
                blue: Double(hexInt & 0x0000FF) / 255.0,
                opacity: 1.0
            )
        } else {
            self = .gray
        }
    }
}

// MARK: - TaskListView
struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    @State private var searchText = ""
    @State private var showingScanner = false
    @State private var lastUpdated: Date? = nil

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Tasks")
                .searchable(text: $searchText, prompt: "Search tasks")
                .onChange(of: searchText) { query in
                    viewModel.handle(intent: .search(query))
                }
                .onAppear {
                    viewModel.handle(intent: .loadTasks)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingScanner.toggle()
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                        }
                    }
                }
                .sheet(isPresented: $showingScanner) {
                    QRCodeScannerView { code in
                        searchText = code
                        viewModel.handle(intent: .search(code))
                    }
                }
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading...")
        case .success(let tasks):
            VStack {
                if let lastUpdated = lastUpdated {
                    Text("Last Updated: \(formattedDate(lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                }
                List(tasks) { task in
                    TaskRow(task: task)
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    await handleRefresh()
                }
            }
        case .error(let message):
            VStack {
                Text("Error: \(message)")
                    .foregroundColor(.red)
                Button("Retry") {
                    viewModel.handle(intent: .loadTasks)
                }
                .padding(.top)
            }
        case .empty:
            Text("No tasks found.")
        }
    }

    // MARK: - Refresh Handling
    private func handleRefresh() async {
        viewModel.handle(intent: .refresh)
        lastUpdated = Date()
    }

    // MARK: - Helper Methods
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - TaskRow
struct TaskRow: View {
    let task: Task

    var body: some View {
        HStack(spacing: 16) {
            if let colorCode = task.colorCode, !colorCode.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: colorCode))
                    .frame(width: 40, height: 40)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(task.task)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}



