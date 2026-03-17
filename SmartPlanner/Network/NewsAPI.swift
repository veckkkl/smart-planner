//
//  NewsAPI.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol Endpoint {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var timeout: TimeInterval { get }
}

extension Endpoint {
    var scheme: String { "https" }
    var queryItems: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
    var timeout: TimeInterval { 30 }

    func makeURLRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.timeoutInterval = timeout

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

enum NewsAPI {
    case topStories(apiKey: String)
    case analyticsEvent(appVersion: String)
}

extension NewsAPI: Endpoint {
    var host: String {
        switch self {
        case .topStories:
            return "api.nytimes.com"
        case .analyticsEvent:
            return "jsonplaceholder.typicode.com"
        }
    }

    var path: String {
        switch self {
        case .topStories:
            return "/svc/topstories/v2/home.json"
        case .analyticsEvent:
            return "/posts"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .topStories:
            return .get
        case .analyticsEvent:
            return .post
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .topStories(let apiKey):
            return [URLQueryItem(name: "api-key", value: apiKey)]
        case .analyticsEvent:
            return []
        }
    }

    var headers: [String : String] {
        switch self {
        case .topStories(let apiKey):
            return [
                "Accept": "application/json",
                "api-key": apiKey
            ]
        case .analyticsEvent:
            return [
                "Content-Type": "application/json; charset=utf-8",
                "Accept": "application/json",
                "X-App-Platform": "iOS"
            ]
        }
    }

    var body: Data? {
        switch self {
        case .topStories:
            return nil
        case .analyticsEvent(let appVersion):
            let payload: [String: Any] = [
                "title": "news_feed_opened",
                "body": "News screen requested NYTimes top stories",
                "userId": 42,
                "appVersion": appVersion,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            return try? JSONSerialization.data(withJSONObject: payload)
        }
    }
}
