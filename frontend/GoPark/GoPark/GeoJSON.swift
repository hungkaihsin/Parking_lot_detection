import Foundation
import CoreLocation

// MARK: - GeoJSON Structures

struct FeatureCollection: Decodable {
    let type: String
    let features: [Feature]
}

struct Feature: Decodable, Identifiable {
    let id: String // Changed to String to match UUID in properties
    let type: String
    let properties: Properties
    let geometry: Geometry

    // Custom initializer to use the 'id' from properties as the Identifiable id
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.properties = try container.decode(Properties.self, forKey: .properties)
        self.geometry = try container.decode(Geometry.self, forKey: .geometry)
        self.id = properties.id // Use the id from properties
    }

    enum CodingKeys: String, CodingKey {
        case type, properties, geometry
    }
}

struct Geometry: Decodable {
    let type: String
    let coordinates: [[CLLocationCoordinate2D]] // Corrected for Polygon
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        var outerCoordinates = try container.nestedUnkeyedContainer(forKey: .coordinates)
        var decodedCoordinates: [[CLLocationCoordinate2D]] = []
        
        while !outerCoordinates.isAtEnd {
            var innerCoordinates = try outerCoordinates.nestedUnkeyedContainer()
            var polygonCoordinates: [CLLocationCoordinate2D] = []
            while !innerCoordinates.isAtEnd {
                var coordinatePair = try innerCoordinates.nestedUnkeyedContainer()
                let longitude = try coordinatePair.decode(CLLocationDegrees.self)
                let latitude = try coordinatePair.decode(CLLocationDegrees.self)
                polygonCoordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
            decodedCoordinates.append(polygonCoordinates)
        }
        coordinates = decodedCoordinates
    }
    
    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
}

struct Properties: Decodable {
    let id: String // Changed to String
    let isEv: Bool
    let isAda: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case isEv = "is_ev"
        case isAda = "is_ada"
    }
}