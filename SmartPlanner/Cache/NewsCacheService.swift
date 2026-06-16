//
//  NewsCacheService.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import Foundation

struct NewsCacheSnapshot {
    let articles: [NewsArticle]
    let savedAt: Date
    let isSoftTTLExpired: Bool
}

protocol NewsCacheServiceProtocol {
    func loadValidCache() -> NewsCacheSnapshot?
    func save(articles: [NewsArticle])
    func removeCache()
}

final class NewsCacheService: NewsCacheServiceProtocol {

    private struct NewsCachePayload: Codable {
        let savedAt: Date
        let articles: [NewsArticle]
    }

    private let fileManager: FileManager
    private let cacheFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let softTTL: TimeInterval = 2 * 60
    private let hardTTL: TimeInterval = 24 * 60 * 60

    init(fileManager: FileManager = .default, cacheDirectoryURL: URL? = nil) {
        self.fileManager = fileManager

        let cacheDirectory = cacheDirectoryURL
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.cacheFileURL = cacheDirectory.appendingPathComponent("news_cache.json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadValidCache() -> NewsCacheSnapshot? {
        guard let payload = loadPayload() else {
            return nil
        }

        let age = Date().timeIntervalSince(payload.savedAt)
        if age > hardTTL {
            removeCache()
            return nil
        }

        return NewsCacheSnapshot(
            articles: payload.articles,
            savedAt: payload.savedAt,
            isSoftTTLExpired: age > softTTL
        )
    }

    func save(articles: [NewsArticle]) {
        let payload = NewsCachePayload(savedAt: Date(), articles: articles)

        do {
            let data = try encoder.encode(payload)
            try data.write(to: cacheFileURL, options: .atomic)
        } catch {
            print("[NewsCacheService] Failed to save cache: \(error.localizedDescription)")
        }
    }

    func removeCache() {
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: cacheFileURL)
        } catch {
            print("[NewsCacheService] Failed to remove cache: \(error.localizedDescription)")
        }
    }

    private func loadPayload() -> NewsCachePayload? {
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            return try decoder.decode(NewsCachePayload.self, from: data)
        } catch {
            print("[NewsCacheService] Failed to read cache: \(error.localizedDescription)")
            return nil
        }
    }
}
