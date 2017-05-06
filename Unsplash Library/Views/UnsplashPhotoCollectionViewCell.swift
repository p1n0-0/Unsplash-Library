//
//  UnsplashPhotoCollectionViewCell.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 27/04/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import UIKit

class UnsplashPhotoCollectionViewCell: UICollectionViewCell {
	
	// MARK: Variables
	
	let downloader:Downloader = Downloader(configuration: .default, delegateQueue: .main)
	
	// MARK: IBOutlets
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var photoImageView: UIImageView!
	@IBOutlet weak var authorLabel: UILabel!
	@IBOutlet weak var likeImage: UIImageView!
	
	// MARK: Functions
	
	func set(photo:UnsplashPhoto) {
		
		// Start activity indicator
		self.activityIndicator.startAnimating()
		
		// Hidden image
		self.photoImageView.isHidden = true
		
		// Set authorLabel
		self.authorLabel.text = photo.author
		
		// Show like image if image is Favourite
		self.likeImage.isHidden = !photo.isFavourite
		
		// Download image
		downloader.downloadWithCache(fromURL: URL(string:"https://unsplash.it/100/100?image=\(photo.id)")!, filename: photo.filename, subFolder: UnsplashPhotoType.thumbnail.rawValue, progressHandler: nil) {
			(data:Data?, response:URLResponse?, error:Error?) in
			
			// Stop activity indicator
			self.activityIndicator.stopAnimating()
			
			// Set image
			if let dataImage = data, let image:UIImage = UIImage(data: dataImage) {
				self.photoImageView.image = image
				photo.thumbnail = image
			} else {
				self.photoImageView.image = #imageLiteral(resourceName: "NoImage")
			}
			
			self.photoImageView.alpha = 0
			UIView.animate(withDuration: 0.5, animations: { 
				self.photoImageView.alpha = 1
			})
			
			// Show image
			self.photoImageView.isHidden = false
			
		}
		
	}
	
	func recycle(){
		
		// Stop previus download if exist
		self.downloader.cancelIgnoringCompletion()
		
	}
	
}
