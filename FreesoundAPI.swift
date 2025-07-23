import Foundation

struct FreesoundSound: Identifiable, Decodable {
    let id: Int
    let name: String
    let previews: PreviewFiles
    
    struct PreviewFiles: Decodable {
        let `default`: URL?    // some keys contain characters like '-' which can't be property names, use default/hq as keys if possible
        let small: URL?        // fallback if needed
        // Freesound API returns keys like "preview-hq-mp3" and "preview-lq-mp3". We'll parse via custom coding keys.
        
        private enum CodingKeys: String, CodingKey {
            case default = "preview_hq_mp3"
            case small = "preview_lq_mp3"
        }
    }
}

/// Handles searching the Freesound.org API and retrieving sound info.
class FreesoundAPI {
    // Insert your Freesound API key here. (Obtain from freesound.org API keys page)
    static let apiKey: String = "<YOUR_API_KEY>"
    static let baseURL: String = "https://freesound.org/apiv2"
    
    /// Perform a text search on Freesound for the given query.
    static func search(query: String) async throws -> [FreesoundSound] {
        // Construct the URL with query and fields parameter to include previews [oai_citation:6‡freesound.org](https://freesound.org/docs/api/resources_apiv2.html#search-resources%23:~:text=Simple%2520search%2520and%2520selection%2520of,to%2520return%2520in%2520the%2520results).
        // The 'fields' parameter is used to get needed metadata (id, name, previews) in one request [oai_citation:7‡freesound.org](https://freesound.org/docs/api/resources_apiv2.html#search-resources%23:~:text=Warning) [oai_citation:8‡freesound.org](https://freesound.org/docs/api/resources_apiv2.html#search-resources%23:~:text=Simple%2520search%2520and%2520selection%2520of,to%2520return%2520in%2520the%2520results).
        guard let url = URL(string: "\(baseURL)/search/text/?query=\(urlEncode(query))&fields=id,name,previews&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Alternatively, we could use an Authorization header [oai_citation:9‡freesound.org](https://freesound.org/docs/api/authentication.html#:~:text=Once%20you%20have%20an%20API,GET%20parameter%E2%80%A6):
        // request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // Decode JSON into a structure containing results array
        struct SearchResponse: Decodable {
            let results: [FreesoundSound]
        }
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.results
    }
    
    /// Utility to URL-encode query parameters
    private static func urlEncode(_ query: String) -> String {
        return query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    }
}
