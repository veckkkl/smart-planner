//
//  APIClient.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import Foundation

enum APIClientError: Error {
    case invalidURL
    case transport(Error)
    case invalidResponse
    case server(code: Int, message: String?)
    case emptyData
    case decoding(Error)
}

extension APIClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL запроса."
        case .transport(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "Нет подключения к интернету."
                case .cannotFindHost:
                    return "Не удалось найти хост API."
                case .cannotConnectToHost:
                    return "Не удалось подключиться к серверу API."
                case .timedOut:
                    return "Истекло время ожидания ответа API."
                default:
                    return "Сетевая ошибка: \(urlError.localizedDescription)"
                }
            }
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .invalidResponse:
            return "Некорректный ответ сервера."
        case .server(let code, let message):
            if code == 401 {
                return "Ошибка авторизации API (401)."
            }
            if code == 403 {
                return "Доступ к API запрещен (403)."
            }
            if code == 429 {
                return "Превышен лимит запросов API (429)."
            }
            if let message, message.isEmpty == false {
                let compact = message.replacingOccurrences(of: "\n", with: " ")
                let short = compact.count > 180 ? String(compact.prefix(180)) + "..." : compact
                return "Ошибка сервера \(code): \(short)"
            }
            return "Ошибка сервера: код \(code)."
        case .emptyData:
            return "Сервер вернул пустой ответ."
        case .decoding(let error):
            return "Ошибка обработки данных: \(error.localizedDescription)"
        }
    }
}

protocol APIClientProtocol {
    @discardableResult
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        decoder: JSONDecoder,
        completion: @escaping (Result<T, APIClientError>) -> Void
    ) -> URLSessionDataTask?

    @discardableResult
    func requestRaw(
        _ endpoint: Endpoint,
        completion: @escaping (Result<Data, APIClientError>) -> Void
    ) -> URLSessionDataTask?
}

final class APIClient: APIClientProtocol {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    @discardableResult
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        decoder: JSONDecoder = JSONDecoder(),
        completion: @escaping (Result<T, APIClientError>) -> Void
    ) -> URLSessionDataTask? {
        requestRaw(endpoint) { result in
            switch result {
            case .success(let data):
                do {
                    let parsed = try decoder.decode(T.self, from: data)
                    completion(.success(parsed))
                } catch {
                    completion(.failure(.decoding(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @discardableResult
    func requestRaw(
        _ endpoint: Endpoint,
        completion: @escaping (Result<Data, APIClientError>) -> Void
    ) -> URLSessionDataTask? {
        let request: URLRequest

        do {
            request = try endpoint.makeURLRequest()
        } catch let error as APIClientError {
            completion(.failure(error))
            return nil
        } catch {
            completion(.failure(.invalidURL))
            return nil
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(.transport(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message: String?
                if let data,
                   let raw = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   raw.isEmpty == false {
                    message = raw
                } else {
                    message = nil
                }
                completion(.failure(.server(code: httpResponse.statusCode, message: message)))
                return
            }

            guard let data else {
                completion(.failure(.emptyData))
                return
            }

            completion(.success(data))
        }

        task.resume()
        return task
    }
}
