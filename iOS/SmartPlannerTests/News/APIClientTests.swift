//
//  APIClientTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class APIClientTests: XCTestCase {

    private var session: URLSession!
    private var sut: APIClient!

    override func setUp() {
        super.setUp()
        let config = MockURLProtocol.register { _ in
            (HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }
        session = URLSession(configuration: config)
        sut = APIClient(session: session)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        session.invalidateAndCancel()
        session = nil
        sut = nil
        super.tearDown()
    }

    func test_buildsRequestUsingEndpointFields() throws {
        var capturedURL: URL?
        var capturedHeaders: [String: String]?
        MockURLProtocol.handler = { request in
            capturedURL = request.url
            capturedHeaders = request.allHTTPHeaderFields
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, "{}".data(using: .utf8))
        }

        let endpoint = TestEndpoint(
            host: "api.example.com",
            path: "/v1/items",
            queryItems: [URLQueryItem(name: "key", value: "abc")],
            headers: ["X-Test": "1"]
        )
        let exp = expectation(description: "done")
        sut.requestRaw(endpoint) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(capturedURL?.absoluteString, "https://api.example.com/v1/items?key=abc")
        XCTAssertEqual(capturedHeaders?["X-Test"], "1")
    }

    func test_successfulResponseDecodes() {
        struct Payload: Decodable, Equatable { let value: Int }
        MockURLProtocol.handler = { request in
            let body = "{\"value\":42}".data(using: .utf8)
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, body)
        }

        let exp = expectation(description: "decoded")
        var captured: Payload?
        sut.request(TestEndpoint(), decoder: JSONDecoder()) { (result: Result<Payload, APIClientError>) in
            if case .success(let value) = result { captured = value }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(captured, Payload(value: 42))
    }

    func test_networkErrorIsMappedToTransport() {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        let exp = expectation(description: "fail")
        var captured: APIClientError?
        sut.requestRaw(TestEndpoint()) { result in
            if case .failure(let error) = result { captured = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        if case .transport = captured {} else { XCTFail("expected .transport") }
    }

    func test_invalidStatusCodeIsMappedToServerError() {
        MockURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!, "denied".data(using: .utf8))
        }

        let exp = expectation(description: "401")
        var captured: APIClientError?
        sut.requestRaw(TestEndpoint()) { result in
            if case .failure(let error) = result { captured = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        guard case .server(let code, _) = captured else {
            XCTFail("expected .server")
            return
        }
        XCTAssertEqual(code, 401)
    }

    func test_decodingErrorIsMappedWhenJSONInvalid() {
        struct Payload: Decodable { let value: Int }
        MockURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, "<not json>".data(using: .utf8))
        }

        let exp = expectation(description: "decoding")
        var captured: APIClientError?
        sut.request(TestEndpoint(), decoder: JSONDecoder()) { (result: Result<Payload, APIClientError>) in
            if case .failure(let error) = result { captured = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        if case .decoding = captured {} else { XCTFail("expected .decoding") }
    }
}

private struct TestEndpoint: Endpoint {
    var host: String = "api.example.com"
    var path: String = "/v1/items"
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
}
