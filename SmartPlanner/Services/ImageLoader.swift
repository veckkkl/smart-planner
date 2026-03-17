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

final class ImageLoader {

    static let shared = ImageLoader()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    @discardableResult
    func loadImage(
        from url: URL,
        completion: @escaping (UIImage?) -> Void
    ) -> ImageLoadTask? {
        let task = session.dataTask(with: url) { data, response, _ in
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let data,
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }
        task.resume()
        return task
    }
}
