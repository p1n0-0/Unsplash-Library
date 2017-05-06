//
//  UnsplashLibrary.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 01/05/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import UIKit

class UnsplashLibrary {
	
	// MARK: Variables
	
	private var library:[UnsplashPhoto]
	
	// MARK: Constructor
	
	init(library:[UnsplashPhoto]) {
		self.library = library
	}
	
	// MARK: Functions
	
	func get() -> [UnsplashPhoto] {
		return self.library
	}
	
	func sort() {
		self.library.sort()
	}
	
	func append(newPhoto:UnsplashPhoto) {
		self.library.append(newPhoto)
	}
	
	func removeAll() {
		self.library.removeAll()
	}
	
	func search(byAuthorWith text:String?) -> [UnsplashPhoto] {
		if let text:String = text, text != "" {
			return library.filter({
				(item:UnsplashPhoto) -> Bool in
				return item.author.contains(text)
			})
		} else{
			return library
		}
	}
	
	func getFavourites() -> [UnsplashPhoto] {
		return library.filter({
			(photo:UnsplashPhoto) -> Bool in
			return photo.isFavourite
		})
	}

}
