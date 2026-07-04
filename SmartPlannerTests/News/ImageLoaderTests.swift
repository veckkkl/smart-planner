//
//  ImageLoaderTests.swift
//  SmartPlannerTests
//

import XCTest
import UIKit
@testable import SmartPlanner

final class ImageLoaderTests: XCTestCase {

    private var session: URLSession!
    private var cache: SpyImageCache!
    private var sut: ImageLoader!
    private let url = URL(string: "https://example.com/img.png")!

    override func setUp() {
        super.setUp()
        let config = MockURLProtocol.register { _ in
            throw URLError(.unknown)
        }
        session = URLSession(configuration: config)
        cache = SpyImageCache()
        sut = ImageLoader(session: session, cacheService: cache)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        session.invalidateAndCancel()
        session = nil
        cache = nil
        sut = nil
        super.tearDown()
    }

    func test_memoryCacheHitSkipsNetwork() {
        let image = makeImage()
        cache.memoryStorage[url] = image

        let exp = expectation(description: "completion")
        var loaded: UIImage?
        let task = sut.loadImage(from: url) { result in
            loaded = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(loaded?.size, image.size)
        XCTAssertFalse(cache.didCallDiskLoad)
    }

    func test_diskCacheHitSkipsNetwork() {
        let image = makeImage()
        cache.diskResponse = image

        let exp = expectation(description: "disk hit")
        var loaded: UIImage?
        let task = sut.loadImage(from: url) { result in
            loaded = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertNotNil(task)

        XCTAssertEqual(loaded?.size, image.size)
    }

    func test_networkSuccessStoresResultInCache() {
        guard let payload = makeImage().pngData() else { return XCTFail("png") }
        MockURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, payload)
        }

        let exp = expectation(description: "network")
        var loaded: UIImage?
        let task = sut.loadImage(from: url) { result in
            loaded = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(task)

        XCTAssertNotNil(loaded)
        XCTAssertTrue(cache.didCallStore)
    }

    func test_networkFailureReturnsNil() {
        MockURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, nil)
        }

        let exp = expectation(description: "fail")
        var loaded: UIImage? = makeImage()
        let task = sut.loadImage(from: url) { result in
            loaded = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(task)

        XCTAssertNil(loaded)
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: format)
        return renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }
}

private final class SpyImageCache: ImageCacheServiceProtocol {
    var memoryStorage: [URL: UIImage] = [:]
    var diskResponse: UIImage?
    private(set) var didCallDiskLoad = false
    private(set) var didCallStore = false

    func imageFromMemory(for url: URL) -> UIImage? { memoryStorage[url] }

    func loadImageFromDisk(for url: URL, completion: @escaping (UIImage?) -> Void) {
        didCallDiskLoad = true
        let response = diskResponse
        DispatchQueue.main.async { completion(response) }
    }

    func store(image: UIImage, originalData: Data, for url: URL) {
        didCallStore = true
        memoryStorage[url] = image
    }
}
