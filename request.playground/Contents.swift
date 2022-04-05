import UIKit

enum ServiceError: Error {
    case invalidURL
    case network(Error?)
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

            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            callback(.success(json))
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
