import Foundation

/// openBD（https://api.openbd.jp）— 1 ISBN につき 1 リクエスト。自動フォールバックはしない。
enum OpenBDClient {
    struct BookInfo: Sendable {
        var title: String?
        var author: String?
        var coverImageURL: URL?
    }

    enum ClientError: Error, LocalizedError {
        case invalidISBN
        case network(Error)
        case noData

        var errorDescription: String? {
            switch self {
            case .invalidISBN: return "ISBN の形式が正しくありません"
            case .network(let e): return e.localizedDescription
            case .noData: return "書籍が見つかりませんでした"
            }
        }
    }

    static func fetch(isbn raw: String) async throws -> BookInfo {
        let isbn = normalizeISBN(raw)
        guard isbn.count == 13 || isbn.count == 10 else { throw ClientError.invalidISBN }
        let url = URL(string: "https://api.openbd.jp/v1/get?isbn=\(isbn)")!
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw ClientError.network(error)
        }
        return try parse(data: data)
    }

    /// ネットワークエラー時に 1 回だけ再試行
    static func fetchWithRetry(isbn: String) async throws -> BookInfo {
        do {
            return try await fetch(isbn: isbn)
        } catch ClientError.network {
            try await Task.sleep(nanoseconds: 350_000_000)
            return try await fetch(isbn: isbn)
        }
    }

    private static func normalizeISBN(_ s: String) -> String {
        s.filter(\.isNumber)
    }

    private static func parse(data: Data) throws -> BookInfo {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [Any],
              let firstAny = root.first
        else {
            throw ClientError.noData
        }
        if firstAny is NSNull { throw ClientError.noData }
        guard let first = firstAny as? [String: Any], !first.isEmpty else {
            throw ClientError.noData
        }
        let summary = first["summary"] as? [String: Any]
        let title = summary?["title"] as? String
        let author = summary?["author"] as? String
        let cover = summary?["cover"] as? String
        let coverURL = cover.flatMap { URL(string: $0) }
        if title == nil, author == nil, coverURL == nil {
            throw ClientError.noData
        }
        return BookInfo(title: title, author: author, coverImageURL: coverURL)
    }

    static func downloadCover(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw ClientError.network(URLError(.badServerResponse))
        }
        return data
    }
}
