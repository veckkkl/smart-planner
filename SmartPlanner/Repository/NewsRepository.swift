//
//  NewsRepository.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import Foundation

enum NewsRepositoryError: Error {
    case invalidAPIStatus(String)
}

protocol NewsRepositoryProtocol {
    func fetchTopStories(completion: @escaping (Result<[NewsArticle], Error>) -> Void)
    func sendAnalyticsEvent()
}

final class NewsRepository: NewsRepositoryProtocol {

    private let apiClient: APIClientProtocol
    private let apiKey: String

    init(
        apiClient: APIClientProtocol = APIClient(),
        apiKey: String = NewsRepository.resolveAPIKey()
    ) {
        self.apiClient = apiClient
        self.apiKey = apiKey
    }

    private static func resolveAPIKey() -> String {
        if let keyFromPlist = Bundle.main.object(forInfoDictionaryKey: "NYT_API_KEY") as? String {
            let trimmed = keyFromPlist.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                return trimmed
            }
        }
        return "AUqBpLx688EFeAUoksb7lS3rAS28MDUDlAsYfJWQZ6UV2rjP"
    }

    func fetchTopStories(completion: @escaping (Result<[NewsArticle], Error>) -> Void) {
        let endpoint = NewsAPI.topStories(apiKey: apiKey)
        let decoder = JSONDecoder()
        if let request = try? endpoint.makeURLRequest() {
            print("[NewsRepository] Request URL: \(request.url?.absoluteString ?? "<nil>")")
        }

        apiClient.request(endpoint, decoder: decoder) { (result: Result<NYTimesTopStoriesResponseDTO, APIClientError>) in
            switch result {
            case .success(let dto):
                if dto.status.uppercased() != "OK" {
                    print("[NewsRepository] NYTimes status is not OK: \(dto.status)")
                    completion(.failure(NewsRepositoryError.invalidAPIStatus(dto.status)))
                    return
                }
                let articles = NYTimesMapper.mapArticles(dto)
                print("[NewsRepository] Loaded \(articles.count) mapped articles from NYTimes")
                completion(.success(articles))

            case .failure(let error):
                print("[NewsRepository] NYTimes request failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func sendAnalyticsEvent() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let endpoint = NewsAPI.analyticsEvent(appVersion: version)

        apiClient.requestRaw(endpoint) { result in
            switch result {
            case .success(let data):
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8-data>"
                print("[AnalyticsRequest] Success response: \(body)")
            case .failure(let error):
                print("[AnalyticsRequest] Failure: \(error)")
            }
        }
    }
}
