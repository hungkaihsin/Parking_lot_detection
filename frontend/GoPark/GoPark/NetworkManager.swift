import Foundation
import CoreLocation // Import CoreLocation for CLLocationCoordinate2D

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func getLotLayout(lotId: String) async throws -> FeatureCollection {
        // For now, return hardcoded GeoJSON data.
        // In the future, this will make a network request to a GeoJSON endpoint.
        let geoJSONString = """
        {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {
                "id": "4ce86c63-3923-4e60-9a39-1a7bce7bd644",
                "is_ev": true,
                "is_ada": false
              },
              "geometry": {
                "type": "Polygon",
                "coordinates": [
                  [
                    [
                      11,
                      41
                    ],
                    [
                      125,
                      38
                    ],
                    [
                      112,
                      263
                    ],
                    [
                      2,
                      266
                    ],
                    [
                      12,
                      45
                    ],
                    [
                      11,
                      41
                    ]
                  ]
                ]
              }
            }
          ]
        }
        """
        
        guard let data = geoJSONString.data(using: .utf8) else {
            throw NetworkError.invalidData
        }
        
        let decoder = JSONDecoder()
        let featureCollection = try decoder.decode(FeatureCollection.self, from: data)
        return featureCollection
    }
}

enum NetworkError: Error {
    case invalidData
}
