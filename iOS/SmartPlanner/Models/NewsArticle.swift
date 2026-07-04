//
//  NewsArticle.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import Foundation

struct NewsArticle: Codable, Hashable {
    let id: String
    let title: String
    let abstract: String
    let source: String
    let publishedAt: Date
    let articleURL: URL?
    let imageURL: URL?
}

struct NYTimesTopStoriesResponseDTO: Decodable {
    let status: String
    let numResults: Int?
    let results: [NYTimesArticleDTO]

    enum CodingKeys: String, CodingKey {
        case status
        case numResults = "num_results"
        case results
    }
}

struct NYTimesArticleDTO: Decodable {
    let title: String?
    let abstract: String?
    let source: String?
    let publishedDate: String?
    let url: String?
    let multimedia: [NYTimesMultimediaDTO]?

    enum CodingKeys: String, CodingKey {
        case title
        case abstract
        case source
        case publishedDate = "published_date"
        case url
        case multimedia
    }
}

struct NYTimesMultimediaDTO: Decodable {
    let url: String?
    let format: String?
    let width: Int?
    let height: Int?
}

enum NYTimesMapper {

    static func mapArticles(_ dto: NYTimesTopStoriesResponseDTO) -> [NewsArticle] {
        dto.results.compactMap { mapArticle($0) }
    }

    private static func mapArticle(_ dto: NYTimesArticleDTO) -> NewsArticle? {
        guard
            let rawTitle = dto.title?.trimmingCharacters(in: .whitespacesAndNewlines),
            rawTitle.isEmpty == false,
            let rawPublishedDate = dto.publishedDate,
            let publishedAt = parseDate(rawPublishedDate)
        else {
            return nil
        }

        let rawAbstract = dto.abstract?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawSource = dto.source?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "NYTimes"

        let articleURL = dto.url.flatMap { URL(string: $0) }
        let imageURL = preferredImageURL(from: dto.multimedia)

        let idSource = (dto.url ?? rawTitle) + rawPublishedDate

        return NewsArticle(
            id: idSource,
            title: rawTitle,
            abstract: rawAbstract,
            source: rawSource.isEmpty ? "NYTimes" : rawSource,
            publishedAt: publishedAt,
            articleURL: articleURL,
            imageURL: imageURL
        )
    }

    private static func preferredImageURL(from multimedia: [NYTimesMultimediaDTO]?) -> URL? {
        guard let multimedia else { return nil }

        let preferredFormats = [
            "superJumbo",
            "threeByTwoSmallAt2X",
            "mediumThreeByTwo440",
            "Large Thumbnail",
            "Normal"
        ]

        for format in preferredFormats {
            if let item = multimedia.first(where: { $0.format == format }),
               let rawURL = item.url,
               let url = URL(string: rawURL) {
                return url
            }
        }

        if let fallback = multimedia
            .sorted(by: { ($0.width ?? 0) > ($1.width ?? 0) })
            .first,
           let rawURL = fallback.url,
           let url = URL(string: rawURL) {
            return url
        }

        return nil
    }

    private static func parseDate(_ raw: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: raw) {
            return date
        }

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        return fallbackFormatter.date(from: raw)
    }
}
