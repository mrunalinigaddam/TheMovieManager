//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "2d32bba39a195036cacc81ddb4cf647f"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case getFavouritelist
        case searchMovie(String)
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout: return "/authentication/session" + Endpoints.apiKeyParam
            case .getFavouritelist: return Endpoints.base + "/account/\(Auth.accountId)/favourite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .searchMovie(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    class func searchMovie(query: String, completion: @escaping([Movie], Error?) -> Void) {
        taskForGetRequest(url: Endpoints.searchMovie(query) .url, response: MovieResults.self)
        { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([] ,error)
            }
        }
    }
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping(ResponseType?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
            let responseObject = try
                decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
            completion(responseObject, nil)
                }
        } catch {
            DispatchQueue.main.async {
            completion(nil, error)
            }
        }
      }
        task.resume()
    }
    class func taskForPostRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL,responseType: ResponseType.Type, body: RequestType, completion: @escaping
        (ResponseType?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try!
        JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task =  URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                  completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try
                decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
    }
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        var request = URLRequest(url: Endpoints.login.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        request.httpBody = try!
            JSONEncoder().encode(body)
        URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            guard let data = data else {
                completion(false, error)
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject = try
                    decoder.decode(RequestTokenResponse.self, from: data)
                Auth.requestToken = responseObject.request_token
                completion(true, nil)
            } catch {
              completion(false, nil)
            }
        }
    }
    
    class func logout(completion: @escaping () -> Void) {
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        let body = LogoutRequest(sessionId:Auth.sessionId)
        request.httpBody = try!
            JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completion()
    }
        task.resume()
    }
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.request_token
                 completion(true, nil)
            }
            else {
                completion(false, error)
            }
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([],error)
            }
        }
        let task = URLSession.shared.dataTask(with: Endpoints.getWatchlist.url) { data, response, error in
            guard let data = data else {
                completion([], error)
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(MovieResults.self, from: data)
                completion(responseObject.results, nil)
            } catch {
                completion([], error)
            }
        }
        task.resume()
    }
    class func getFavouritelist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getFavouritelist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([],error)
            }
        }
//        let task = URLSession.shared.dataTask(with: Endpoints.getWatchlist.url) { data, response, error in
//            guard let data = data else {
//                completion([], error)
//                return
//            }
//            let decoder = JSONDecoder()
//            do {
//                let responseObject = try decoder.decode(MovieResults.self, from: data)
//                completion(responseObject.results, nil)
//            } catch {
//                completion([], error)
//            }
//        }
//        task.resume()
    }
    class func createSessionId(completion: @escaping (Bool, Error?) -> Void) {
        var request = URLRequest(url:Endpoints.createSessionId.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PostSession(requestToken: Auth.requestToken)
        request.httpBody = try!
            JSONEncoder().encode(body)
        let task = URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            guard let data = data else {
                completion(false, error)
                return
            }
            do
            {
                let decoder = JSONDecoder()
                let responseObject = try
                    decoder.decode(SessionResponse.self, from: data)
                Auth.sessionId = responseObject.sessionId
                completion(true, nil)
            } catch {
                completion(false, nil)
            }
            
        }
        task.resume()
    }
}
