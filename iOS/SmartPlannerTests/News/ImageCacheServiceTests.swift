//
//  ImageCacheServiceTests.swift
//  SmartPlannerTests
//

import XCTest
import UIKit
@testable import SmartPlanner

final class ImageCacheServiceTests: XCTestCase {

    private var tempDirectory: URL!
    private var sut: ImageCacheService!

    private let url = URL(string: "https://example.com/pic.png")!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageCacheServiceTests-\(UUID().uuidString)", isDirectory: true)
        sut = ImageCacheService(cacheDirectoryURL: tempDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        sut = nil
        try super.tearDownWithError()
    }

    func test_memoryCacheMissReturnsNil() {
        XCTAssertNil(sut.imageFromMemory(for: url))
    }

    func test_storePopulatesMemoryCache() {
        let image = makeImage()
        let data = try? XCTUnwrap(image.pngData())
        XCTAssertNotNil(data)

        sut.store(image: image, originalData: data ?? Data(), for: url)

        XCTAssertNotNil(sut.imageFromMemory(for: url))
    }

    func test_storeWritesToDiskAndCanBeReadBack() {
        let image = makeImage()
        guard let data = image.pngData() else {
            return XCTFail("png data")
        }
        sut.store(image: image, originalData: data, for: url)

        let exp = expectation(description: "disk read")
        var loaded: UIImage?
        sut.loadImageFromDisk(for: url) { result in
            loaded = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)

        XCTAssertNotNil(loaded)
    }

    func test_loadFromDiskReturnsNilOnCacheMiss() {
        let exp = expectation(description: "miss")
        var loaded: UIImage? = makeImage()
        sut.loadImageFromDisk(for: URL(string: "https://example.com/unknown.png")!) { result in
            loaded = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        XCTAssertNil(loaded)
    }

    func test_separateUrlsAreIsolated() {
        let image = makeImage()
        guard let data = image.pngData() else { return XCTFail("png data") }
        sut.store(image: image, originalData: data, for: url)

        let other = URL(string: "https://example.com/different.png")!
        XCTAssertNil(sut.imageFromMemory(for: other))
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: format)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }
}
