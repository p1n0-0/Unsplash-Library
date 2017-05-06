//
//  PhotoDetailViewController.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 27/04/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import UIKit
import CoreImage

let PhotoIsFavoriteDidChangeNotification = Notification.Name(rawValue: "Photo isFavorite property did change")

class PhotoDetailViewController: UIViewController {
	
	// MARK: Variables
	
	var photo:UnsplashPhoto?
	let downloader:Downloader = Downloader(configuration: .default, delegateQueue: .main)
	var photoDownloaded:UIImage?
	var photoEffectView:UIVisualEffectView = UIVisualEffectView()
	
	// MARK: IBOutlets
	
	@IBOutlet weak var authorWebPageButton: UIBarButtonItem!
	@IBOutlet weak var shareButton: UIBarButtonItem!
	@IBOutlet weak var filtersButton: UIBarButtonItem!
	@IBOutlet weak var postButton: UIBarButtonItem!
	@IBOutlet weak var likeButton: UIBarButtonItem!
	@IBOutlet weak var photoImageView: UIImageView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var downloadProgressView: UIProgressView!
	
	// MARK: UIViewController
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		// Adding effect view in photo image view, adding autoresizing settings & setting frame
		self.photoEffectView.frame = self.photoImageView.bounds
		self.photoEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.photoImageView.addSubview(self.photoEffectView)
		
		let tgr = UITapGestureRecognizer(target: self, action: #selector(PhotoDetailViewController.markLikedOrUnlikedPhoto(_:)))
		tgr.numberOfTapsRequired = 2
		self.view.addGestureRecognizer(tgr)
		
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let photo:UnsplashPhoto = self.photo {
			
			self.title = photo.author
			
			if photo.isFavourite {
				self.likeButton.image = #imageLiteral(resourceName: "Heart-In-Button")
			}
			
			// Start activity indicator & progress view
			self.activityIndicator.startAnimating()
			self.downloadProgressView.isHidden = false
			self.downloadProgressView.progress = 0.0
			
			if let thumbnail = photo.thumbnail {
				self.photoEffectView.effect = UIBlurEffect(style: .light)
				self.photoImageView.contentMode = .scaleAspectFit
				self.photoImageView.image = imageWithImage(image: thumbnail, scaledToSize: CGSize(width: photo.width/100, height: photo.height/100))
			} else {
				self.photoImageView.isHidden = true
			}
			
			// Download image
			downloader.downloadWithCache(fromURL: URL(string:"https://unsplash.it/\(photo.width)/\(photo.height)?image=\(photo.id)")!, filename: photo.filename, subFolder: UnsplashPhotoType.original.rawValue, progressHandler: {
				(progress:Float) in
				
				// Update progress
				self.downloadProgressView.progress = progress
				
			}, completionHandler: {
				(data:Data?, response:URLResponse?, error:Error?) in
				
				// Stop activity indicator & progress view
				self.downloadProgressView.isHidden = true
				self.activityIndicator.stopAnimating()
				
				// Set image
				if let dataImage = data, let image:UIImage = UIImage(data: dataImage) {
					self.photoDownloaded = image
					self.photoImageView.contentMode = .scaleAspectFit
					self.photoImageView.image = image
					self.photoEffectView.effect = UIBlurEffect(style: .light)
					UIView.animate(withDuration: 0.5) {
						self.photoEffectView.effect = nil
					}
				} else {
					self.photoImageView.contentMode = .center
					self.photoImageView.image = #imageLiteral(resourceName: "NoImage")
				}
				
				// Show image
				self.photoImageView.isHidden = false
				
			})
			
		} else {
			
			self.photoImageView.contentMode = .center
			self.photoImageView.image = #imageLiteral(resourceName: "NoImage")
			
		}
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Stop download task
		self.downloader.cancelIgnoringCompletion()
		
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: IBActions
    
	@IBAction func showAuthorWebPage(_ sender: Any) {
		if let photo:UnsplashPhoto = self.photo {
			if !UIApplication.shared.openURL(photo.authorURL) {
				print("Failed to open url: \(photo.authorURL.description)")
			}
		}
	}
	
	@IBAction func showPostWebPage(_ sender: Any) {
		if let photo:UnsplashPhoto = self.photo {
			if !UIApplication.shared.openURL(photo.postURL) {
				print("Failed to open url: \(photo.postURL.description)")
			}
		}
	}
	
	@IBAction func sharePhoto(_ sender: Any) {
		
		if self.activityIndicator.isAnimating == false {
		
			if let photo:UnsplashPhoto = self.photo,
				let photoImage:UIImage = self.photoDownloaded {
				
					var sharingItems = [AnyObject]()
					sharingItems.append(photoImage as AnyObject)
					sharingItems.append(photo.author as AnyObject)
					sharingItems.append(photo.postURL as AnyObject)
					
					let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
					
					self.present(activityViewController, animated: true, completion: nil)

			} else {
				
				self.displayAlert(title: "No image avaliable", message: "The image must be available to share.")
				
			}
		
		}
	
	}
	
	@IBAction func markLikedOrUnlikedPhoto(_ sender: Any) {
		
		if let photo:UnsplashPhoto = self.photo {
			
			if photo.isFavourite {
				photo.isFavourite = false
				self.likeButton.image = #imageLiteral(resourceName: "Heart-Out-Button")
			} else {
				photo.isFavourite = true
				self.likeButton.image = #imageLiteral(resourceName: "Heart-In-Button")
			}
			
			let notification = Notification(name: PhotoIsFavoriteDidChangeNotification)
			NotificationCenter.default.post(notification)
			
		}
		
	}
	

	@IBAction func selectFilter(_ sender: Any) {
		
		if self.activityIndicator.isAnimating == false {
		
			if let _:UIImage = self.photoDownloaded {
			
					let filters:[(String,String,Float?)] = [("Sepia","CISepiaTone",0.5),
															("Transfer","CIPhotoEffectTransfer",nil),
															("Color Invert","CIColorInvert",nil),
															("Gaussian Blur","CIGaussianBlur",nil),
															("Chrome","CIPhotoEffectChrome",nil),
															("Noir","CIPhotoEffectNoir",nil)]
					
					let actionSheet:UIAlertController = UIAlertController(title: "Select filter", message: nil, preferredStyle: (UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert))
					
					for filter in filters {
						
						actionSheet.addAction(UIAlertAction(title: filter.0, style: .default, handler: {
							(_:UIAlertAction) in
							
							actionSheet.dismiss(animated: true, completion: nil);
							
							self.apply(filter: filter.1, withIntensity: filter.2)
							
						}))
						
					}
					
					actionSheet.addAction(UIAlertAction(title: "No filter", style: .destructive, handler: {
						(_:UIAlertAction) in
						
						actionSheet.dismiss(animated: true, completion: nil);
						
						UIView.animate(withDuration: 0.5, animations: { 
							self.photoEffectView.effect = UIBlurEffect(style: .light)
						}, completion: {
							(_:Bool) in
							self.photoImageView.image = self.photoDownloaded
							UIView.animate(withDuration: 0.5) {
								self.photoEffectView.effect = nil
							}
						})
						
					}))
					
					actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
						(_:UIAlertAction) in
						actionSheet.dismiss(animated: true, completion: nil);
					}))
					
					self.present(actionSheet, animated: true, completion: nil)
				
			} else {
				
				self.displayAlert(title: "No image avaliable", message: "The image must be available to apply a filter.")
				
			}
			
		}
		
	}
	
	// MARK: Functions
	
	// Apply filter
	func apply(filter:String, withIntensity intensity:Float?) {
		if let photoImage:UIImage = self.photoDownloaded {
			
			UIView.animate(withDuration: 0.5, animations: {
				self.photoEffectView.effect = UIBlurEffect(style: .light)
			}, completion: {
				(_:Bool) in
				self.activityIndicator.startAnimating()
				self.set(filter: CIFilter(name: filter)!, withIntensity: intensity, overImage: photoImage, completionHandler: {
					(image:UIImage?) in
					
					self.activityIndicator.stopAnimating()
					
					if let image = image {
						self.photoImageView.contentMode = .scaleAspectFit
						self.photoImageView.image = image
					}
					
					UIView.animate(withDuration: 0.5) {
						self.photoEffectView.effect = nil
					}
					
				})
			})
			
		}
	}
	
	// Apply filter in a image using Core Image & GCD
	func set(filter:CIFilter, withIntensity intensity:Float?, overImage image:UIImage, completionHandler:@escaping (_ image:UIImage?)->()) {
		
		// Check if image is convertible in Core Image
		guard let coreImage = CIImage(image: image) else {
			return completionHandler(nil)
		}
		
		// Create CoreImage Context
		let context = CIContext(options: nil)
		
		// Apply image & intensity in filter
		filter.setValue(coreImage, forKey: kCIInputImageKey)
		if let intensity = intensity {
			filter.setValue(intensity, forKey: kCIInputIntensityKey)
		}
		
		// Go to background
		DispatchQueue.global(qos: .utility).async {
			
			// Obtain image with filter applied
			if let output:CIImage = filter.outputImage {
				
				// In foreground obtain image if Core Image context create CGIimage
				DispatchQueue.main.async {
					if let cgimg = context.createCGImage(output, from: output.extent) {
						return completionHandler(UIImage(cgImage: cgimg))
					} else {
						return completionHandler(nil)
					}
				}

			} else {
				
				// Return nil in completionHandler
				DispatchQueue.main.async {
					return completionHandler(nil)
				}
				
			}
			
		}
	}
	
	// http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
	func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
		image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
		let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		return newImage
	}
	
	// Display alert
	func displayAlert(title:String, message:String){
		
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {
			(_:UIAlertAction) in
			alert.dismiss(animated: true, completion: nil)
		}))
		self.present(alert, animated: true, completion: nil)
		
	}
	
}
