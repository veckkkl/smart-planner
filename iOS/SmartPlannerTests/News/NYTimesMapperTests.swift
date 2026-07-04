//
//  NYTimesMapperTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class NYTimesMapperTests: XCTestCase {

    func test_mapsValidArticleWithAllFields() {
        let dto = makeResponse(articles: [
            article(
                title: "Breaking News",
                abstract: "Something happened",
                source: "NY Times",
                publishedDate: "2026-06-15T14:30:00-04:00",
                url: "https://example.com/story",
                multimedia: [media(url: "https://example.com/img-large.jpg", format: "superJumbo", width: 2000)]
            )
        ])

        let result = NYTimesMapper.mapArticles(dto)

        XCTAssertEqual(result.count, 1)
        let mapped = try? XCTUnwrap(result.first)
        XCTAssertEqual(mapped?.title, "Breaking News")
        XCTAssertEqual(mapped?.abstract, "Something happened")
        XCTAssertEqual(mapped?.source, "NY Times")
        XCTAssertEqual(mapped?.articleURL, URL(string: "https://example.com/story"))
        XCTAssertEqual(mapped?.imageURL, URL(string: "https://example.com/img-large.jpg"))
    }

    func test_mapsArticleWithoutMultimediaToNilImage() {
        let dto = makeResponse(articles: [
            article(publishedDate: "2026-06-15T14:30:00-04:00", multimedia: nil)
        ])

        let result = NYTimesMapper.mapArticles(dto)

        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result.first?.imageURL)
    }

    func test_mapsArticleWithEmptyMultimediaArrayToNilImage() {
        let dto = makeResponse(articles: [
            article(publishedDate: "2026-06-15T14:30:00-04:00", multimedia: [])
        ])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertNil(result.first?.imageURL)
    }

    func test_mapsArticleWithEmptyAbstractToEmptyString() {
        let dto = makeResponse(articles: [
            article(abstract: "   ", publishedDate: "2026-06-15T14:30:00-04:00")
        ])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertEqual(result.first?.abstract, "")
    }

    func test_filtersOutArticlesWithoutTitle() {
        let dto = makeResponse(articles: [
            article(title: nil, publishedDate: "2026-06-15T14:30:00-04:00"),
            article(title: "  ", publishedDate: "2026-06-15T14:30:00-04:00"),
            article(title: "OK", publishedDate: "2026-06-15T14:30:00-04:00")
        ])

        let result = NYTimesMapper.mapArticles(dto)

        XCTAssertEqual(result.map(\.title), ["OK"])
    }

    func test_filtersOutArticlesWithUnparseableDate() {
        let dto = makeResponse(articles: [
            article(publishedDate: "not-a-date"),
            article(publishedDate: nil),
            article(title: "Good", publishedDate: "2026-06-15T14:30:00-04:00")
        ])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertEqual(result.map(\.title), ["Good"])
    }

    func test_publishedDateMapsStablyFromIsoString() {
        let iso = "2026-06-15T14:30:00-04:00"
        let dto = makeResponse(articles: [article(publishedDate: iso)])

        let result = NYTimesMapper.mapArticles(dto)
        let mapped = result.first

        let expected = ISO8601DateFormatter().date(from: iso)
        XCTAssertEqual(mapped?.publishedAt, expected)
    }

    func test_supportsFractionalSecondsInDate() {
        let iso = "2026-06-15T14:30:00.123-04:00"
        let dto = makeResponse(articles: [article(publishedDate: iso)])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertEqual(result.count, 1)
    }

    func test_defaultSourceWhenMissing() {
        let dto = makeResponse(articles: [
            article(source: nil, publishedDate: "2026-06-15T14:30:00-04:00")
        ])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertEqual(result.first?.source, "NYTimes")
    }

    func test_picksPreferredFormatOverOthers() {
        let dto = makeResponse(articles: [
            article(
                publishedDate: "2026-06-15T14:30:00-04:00",
                multimedia: [
                    media(url: "https://example.com/normal.jpg", format: "Normal", width: 100),
                    media(url: "https://example.com/super.jpg", format: "superJumbo", width: 2000),
                    media(url: "https://example.com/large.jpg", format: "Large Thumbnail", width: 400)
                ]
            )
        ])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertEqual(result.first?.imageURL, URL(string: "https://example.com/super.jpg"))
    }

    func test_fallsBackToWidestImageWhenNoPreferredFormat() {
        let dto = makeResponse(articles: [
            article(
                publishedDate: "2026-06-15T14:30:00-04:00",
                multimedia: [
                    media(url: "https://example.com/small.jpg", format: "X", width: 100),
                    media(url: "https://example.com/big.jpg", format: "Y", width: 1500)
                ]
            )
        ])

        let result = NYTimesMapper.mapArticles(dto)
        XCTAssertEqual(result.first?.imageURL, URL(string: "https://example.com/big.jpg"))
    }

    // MARK: helpers

    private func makeResponse(articles: [NYTimesArticleDTO]) -> NYTimesTopStoriesResponseDTO {
        NYTimesTopStoriesResponseDTO(status: "OK", numResults: articles.count, results: articles)
    }

    private func article(
        title: String? = "T",
        abstract: String? = "A",
        source: String? = "NY Times",
        publishedDate: String? = nil,
        url: String? = "https://example.com",
        multimedia: [NYTimesMultimediaDTO]? = nil
    ) -> NYTimesArticleDTO {
        NYTimesArticleDTO(
            title: title,
            abstract: abstract,
            source: source,
            publishedDate: publishedDate,
            url: url,
            multimedia: multimedia
        )
    }

    private func media(url: String?, format: String?, width: Int?) -> NYTimesMultimediaDTO {
        NYTimesMultimediaDTO(url: url, format: format, width: width, height: width)
    }
}
