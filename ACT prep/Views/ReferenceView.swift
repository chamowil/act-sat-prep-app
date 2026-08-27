//
//  ReferenceView.swift
//  ACT prep
//
//  Searchable rulebook: grammar and punctuation rules, math formula families,
//  and reading/science strategy, each with worked right-vs-wrong examples.
//

import SwiftUI

struct ReferenceView: View {
    @State private var searchText = ""
    @State private var store = StoreManager.shared
    @State private var showPaywall = false

    private var library: StudyLibrary { .shared }

    private var results: [ReferenceEntry] { library.searchReference(searchText) }

    var body: some View {
        List {
            if searchText.isEmpty {
                ForEach(library.referenceCategories, id: \.self) { category in
                    Section(category) {
                        ForEach(library.reference(in: category)) { entry in
                            row(entry)
                        }
                    }
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                Section("\(results.count) result\(results.count == 1 ? "" : "s")") {
                    ForEach(results) { entry in
                        row(entry)
                    }
                }
            }
        }
        .navigationTitle("Quick Reference")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $searchText, prompt: "Search rules and formulas")
        .navigationDestination(for: ReferenceEntry.self) { entry in
            ReferenceDetailView(entry: entry)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    @ViewBuilder
    private func row(_ entry: ReferenceEntry) -> some View {
        if isUnlocked(entry) {
            NavigationLink(value: entry) {
                content(entry, locked: false)
            }
        } else {
            Button {
                showPaywall = true
            } label: {
                content(entry, locked: true)
            }
            .buttonStyle(.plain)
        }
    }

    /// The first three entries in each category are free.
    private func isUnlocked(_ entry: ReferenceEntry) -> Bool {
        if store.isPro { return true }
        let siblings = library.reference(in: entry.category)
        guard let index = siblings.firstIndex(of: entry) else { return false }
        return index < 3
    }

    private func content(_ entry: ReferenceEntry, locked: Bool) -> some View {
        HStack(spacing: 12) {
            if locked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(entry.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

struct ReferenceDetailView: View {
    let entry: ReferenceEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    TagPill(text: entry.category)
                    Text(entry.title)
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(entry.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                VStack(alignment: .leading, spacing: 8) {
                    Text("The Rule")
                        .font(.headline)
                    Text(entry.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()

                if !entry.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples")
                            .font(.headline)
                        ForEach(Array(entry.examples.enumerated()), id: \.offset) { _, example in
                            VStack(alignment: .leading, spacing: 8) {
                                exampleRow("xmark.circle.fill", .red, example.wrong)
                                exampleRow("checkmark.circle.fill", .green, example.right)
                                Text(example.why)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appGroupedBackground,
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .cardBackground()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Common Trap", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text(entry.trap)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardBackground()
            }
            .padding()
            .readableWidth()
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(entry.category)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func exampleRow(_ symbol: String, _ tint: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
