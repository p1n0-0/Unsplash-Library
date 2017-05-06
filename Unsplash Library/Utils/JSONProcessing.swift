//
//  JSONProcessing.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 27/04/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import Foundation

// MARK: Aliases

typealias JSONObject        =   AnyObject
typealias JSONDictionary    =   [String : JSONObject]
typealias JSONArray         =   [JSONDictionary]

// MARK: JSON Errors

enum JSONError : Error{
	case wrongURLFormatForJSONResource
	case resourcePointedByURLNotReachable
	case jsonParsingError
	case wrongJSONFormat
	case nilJSONObject
}

// MARK: Decodification

func decode(unsplashPhoto json:JSONDictionary) throws -> UnsplashPhoto {
	
	guard let id = json["id"] as? Int else {
		throw JSONError.jsonParsingError
	}
	
	guard let format = json["format"] as? String else {
		throw JSONError.jsonParsingError
	}
	
	guard let width = json["width"] as? Int else {
		throw JSONError.jsonParsingError
	}
	
	guard let height = json["height"] as? Int else {
		throw JSONError.jsonParsingError
	}
	
	guard let filename = json["filename"] as? String else {
		throw JSONError.jsonParsingError
	}
	
	guard let author = json["author"] as? String else {
		throw JSONError.jsonParsingError
	}
	
	guard let author_url = json["author_url"] as? String,
		let authorURL = URL(string: author_url) else {
		throw JSONError.wrongURLFormatForJSONResource
	}
	
	guard let post_url = json["post_url"] as? String,
          let postURL = URL(string: post_url)else {
		throw JSONError.wrongURLFormatForJSONResource
	}
	
	return UnsplashPhoto(id: id, format: format, width: width, height: height, filename: filename, author: author, authorURL: authorURL, postURL: postURL)
	
}

func decode(unsplashPhoto json:JSONDictionary?) throws -> UnsplashPhoto {
	if case .some(let jsonDict) = json {
		return try decode(unsplashPhoto: jsonDict)
	} else {
		throw JSONError.nilJSONObject
	}
}

// MARK: Loading

func load(fromData data:Data) throws -> JSONArray {
	if let maybeArray = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? JSONArray, let array = maybeArray {
		return array
	}else{
		throw JSONError.jsonParsingError
	}
}
