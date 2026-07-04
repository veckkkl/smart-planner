//
//  ImageLoader.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import UIKit

protocol ImageLoadTask {
    func cancel()
}

extension URLSessionDataTask: ImageLoadTask {}

private final class ImageLoaderOperation: ImageLoadTask {

    private let lock = NSLock()
    private var isCancelledValue = false
    private var networkTask: URLSessionDataTask?

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelledValue
    }

    func setNetworkTask(_ task: URLSessionDataTask) {
        lock.lock()
        if isCancelledValue {
            lock.unlock()
            task.cancel()
            return
        }
        networkTask = task
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        isCancelledValue = true
        let task = networkTask
        networkTask = nil
        lock.unlock()

        task?.cancel()
    }
}

final class ImageLoader {

    static let shared = ImageLoader()

    private let session: URLSession
    private let cacheService: ImageCacheServiceProtocol

    init(
        session: URLSession = .shared,
        cacheService: ImageCacheServiceProtocol = ImageCacheService.shared
    ) {
        self.session = session
        self.cacheService = cacheService
    }

    @discardableResult
    func loadImage(
        from url: URL,
        completion: @escaping (UIImage?) -> Void
    ) -> ImageLoadTask? {
        if let cachedImage = cacheService.imageFromMemory(for: url) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return nil
        }

        let operation = ImageLoaderOperation()

        cacheService.loadImageFromDisk(for: url) { [weak self, weak operation] cachedFromDisk in
            guard let operation else { return }
            guard operation.isCancelled == false else { return }

            if let cachedFromDisk {
                completion(cachedFromDisk)
                return
            }

            guard let self else {
                completion(nil)
                return
            }

            let task = self.session.dataTask(with: url) { [weak self, weak operation] data, response, _ in
                guard let operation else { return }
                guard operation.isCancelled == false else { return }

                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode),
                    let data,
                    let image = UIImage(data: data)
                else {
                    DispatchQueue.main.async {
                        if operation.isCancelled == false {
                            completion(nil)
                        }
                    }
                    return
                }

                self?.cacheService.store(image: image, originalData: data, for: url)

                DispatchQueue.main.async {
                    if operation.isCancelled == false {
                        completion(image)
                    }
                }
            }

            operation.setNetworkTask(task)
            task.resume()
        }

        return operation
    }
}
