//
//  UnsplashPhoto.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 27/04/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import UIKit

enum UnsplashPhotoType: String {
	case thumbnail = "thumbnails"
	case original = "originals"
}

class UnsplashPhoto: Equatable, Comparable {
	
	// MARK: Static

	static let imageFavouritesUserDefault = UserDefaults(suiteName: "imagesFavourites")!
	
	// MARK: Variables
	
	let id:Int
	let format:String
	let width:Int
	let height:Int
	let filename:String
	let author:String
	let authorURL:URL
	let postURL:URL
	var thumbnail:UIImage?
	
	// MARK: Computed Variables
	
	var isFavourite:Bool {
		get {
			return UnsplashPhoto.imageFavouritesUserDefault.bool(forKey: "image-\(self.id)")
		}
		set(newValue){
			UnsplashPhoto.imageFavouritesUserDefault.setValue(newValue, forKey: "image-\(self.id)")
			UnsplashPhoto.imageFavouritesUserDefault.synchronize()
		}
	}
	
	
	// MARK: Constructor
	
	init(id:Int, format:String, width:Int, height:Int, filename:String, author:String, authorURL:URL, postURL:URL) {
		self.id = id
		self.format = format
		self.width = width
		self.height = height
		self.filename = filename
		self.author = author
		self.authorURL = authorURL
		self.postURL = postURL
	}
	
	// MARK: Proxies
	
	var proxyForComparison : String{
		get{
			return "\(author)\(filename)\(id)"
		}
	}
	
	var proxyForSorting : String{
		get{
			return proxyForComparison
		}
	}
	
}

// MARK: Equatable & Comparable

func ==(lhs: UnsplashPhoto, rhs: UnsplashPhoto) -> Bool {
	guard (lhs !== rhs) else {
		return true
	}
	return lhs.proxyForComparison == rhs.proxyForComparison
}

func <(lhs: UnsplashPhoto, rhs: UnsplashPhoto) -> Bool {
	return lhs.proxyForSorting < rhs.proxyForSorting
}

// MARK: Extensions

extension UnsplashPhoto: CustomStringConvertible {
	
	var description: String {
		get {
			return "< \(type(of: self)) \(self.filename) made by \(self.author)>"
		}
	}
	
}
