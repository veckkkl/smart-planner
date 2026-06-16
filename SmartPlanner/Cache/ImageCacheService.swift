//
//  ImageCacheService.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import CryptoKit
import UIKit

protocol ImageCacheServiceProtocol {
    func imageFromMemory(for url: URL) -> UIImage?
    func loadImageFromDisk(for url: URL, completion: @escaping (UIImage?) -> Void)
    func store(image: UIImage, originalData: Data, for url: URL)
}

final class ImageCacheService: ImageCacheServiceProtocol {

    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager: FileManager
    private let diskDirectoryURL: URL
    private let ioQueue = DispatchQueue(label: "com.smartplanner.image-cache", qos: .utility)

    private let maxDiskItemAge: TimeInterval = 7 * 24 * 60 * 60
    private var didScheduleCleanup = false

    init(fileManager: FileManager = .default, cacheDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        if let cacheDirectoryURL {
            self.diskDirectoryURL = cacheDirectoryURL
        } else {
            let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.diskDirectoryURL = cacheDirectory.appendingPathComponent("NewsImages", isDirectory: true)
        }

        ioQueue.async { [weak self] in
            self?.prepareDiskDirectoryIfNeeded()
            self?.cleanupExpiredFilesIfNeeded()
        }
    }

    func imageFromMemory(for url: URL) -> UIImage? {
        memoryCache.object(forKey: url as NSURL)
    }

    func loadImageFromDisk(for url: URL, completion: @escaping (UIImage?) -> Void) {
        ioQueue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            self.prepareDiskDirectoryIfNeeded()
            self.cleanupExpiredFilesIfNeeded()

            let fileURL = self.fileURL(for: url)
            guard
                let data = try? Data(contentsOf: fileURL),
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            self.memoryCache.setObject(image, forKey: url as NSURL)
            try? self.fileManager.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: fileURL.path
            )

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func store(image: UIImage, originalData: Data, for url: URL) {
        memoryCache.setObject(image, forKey: url as NSURL)

        ioQueue.async { [weak self] in
            guard let self else { return }
            self.prepareDiskDirectoryIfNeeded()
            self.cleanupExpiredFilesIfNeeded()

            let fileURL = self.fileURL(for: url)
            do {
                try originalData.write(to: fileURL, options: .atomic)
            } catch {
                print("[ImageCacheService] Failed to write image cache: \(error.localizedDescription)")
            }
        }
    }

    private func prepareDiskDirectoryIfNeeded() {
        guard fileManager.fileExists(atPath: diskDirectoryURL.path) == false else {
            return
        }

        do {
            try fileManager.createDirectory(at: diskDirectoryURL, withIntermediateDirectories: true)
        } catch {
            print("[ImageCacheService] Failed to create cache directory: \(error.localizedDescription)")
        }
    }

    private func cleanupExpiredFilesIfNeeded() {
        guard didScheduleCleanup == false else {
            return
        }
        didScheduleCleanup = true

        let expirationDate = Date().addingTimeInterval(-maxDiskItemAge)
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .contentModificationDateKey,
            .creationDateKey
        ]

        guard let files = try? fileManager.contentsOfDirectory(
            at: diskDirectoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for fileURL in files {
            guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
                  values.isRegularFile == true else {
                continue
            }

            let fileDate = values.contentModificationDate ?? values.creationDate ?? .distantPast
            if fileDate < expirationDate {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    private func fileURL(for url: URL) -> URL {
        diskDirectoryURL.appendingPathComponent(hashedFileName(for: url))
    }

    private func hashedFileName(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let digest = SHA256.hash(data: data)
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return "\(hash).img"
    }
}
