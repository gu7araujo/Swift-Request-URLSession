import UIKit

struct Brewery: Decodable {
    let id, name, breweryType: String
    let street: String?
    let city, state, postalCode, country: String
    let longitude, latitude, phone: String?
    let websiteURL: String?
    let updatedAt, createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case breweryType = "brewery_type"
        case street, city, state
        case postalCode = "postal_code"
        case country, longitude, latitude, phone
        case websiteURL = "website_url"
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}

enum ServiceError: Error {
    case invalidURL
    case network(Error?)
    case decodeFail(Error?)
}

enum RequestType: String {
    case getRequest = "GET"
}

//Swift 5.5 Async/await
class ApiManager {
    private let baseURL = "https://api.openbrewerydb.org/breweries"

    static var shared = ApiManager()

    private var request: URLRequest?

    private init () {}

    func sendRequest(parameters: [String: Any]) async -> Result<[Brewery], Error>? {
        do {
            guard let urlRequest = createGetRequestWithURLComponents(parameters: parameters) else {
                return nil
            }

            let (data, _) = try await URLSession.shared.data(for: urlRequest)

            let parsedData = try JSONDecoder().decode([Brewery].self, from: data)

            return .success(parsedData)
        } catch {
            return .failure(error)
        }
    }

    private func createGetRequestWithURLComponents(parameters: [String: Any]) -> URLRequest? {
        var components = URLComponents(string: baseURL)!

        components.queryItems = parameters.map({ (key: String, value: Any) in
            URLQueryItem(name: key, value: "\(value)")
        })

        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")

        request = URLRequest(url: components.url!)

        request?.httpMethod = RequestType.getRequest.rawValue

        return request
    }
}

Task.init {
    func sendApiCall() async {
        guard let result = await ApiManager.shared.sendRequest(parameters: [:]) else {
            return
        }

        switch result {
        case .success(let data):
            print(data)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }

    await sendApiCall()
}



class Service {
    private let baseURL = "https://api.openbrewerydb.org/breweries"

    func get(callback: @escaping (Result<Any, ServiceError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            return callback(.failure(.invalidURL))
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                return callback(.failure(.network(error)))
            }

            do {
                let json = try JSONDecoder().decode([Brewery].self, from: data)
                callback(.success(json))
            } catch {
                callback(.failure(.decodeFail(error)))
            }
        }.resume()
    }
}

do {
    let service = Service()

    service.get { result in
        DispatchQueue.main.async {
            switch result {
            case let .failure(error):
                print(error)
            case let .success(data):
                print(data)
            }
        }
    }
}
