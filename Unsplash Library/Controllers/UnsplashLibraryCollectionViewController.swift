//
//  UnsplashLibraryCollectionViewController.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 27/04/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import UIKit

class UnsplashLibraryCollectionViewController: UICollectionViewController, UISearchBarDelegate {
	
	// MARK: Variables

	let refresher: UIRefreshControl = UIRefreshControl()
	let library:UnsplashLibrary = UnsplashLibrary(library: [])
	var unsplashPhotos:[UnsplashPhoto] = []
	var selectedPhoto:UnsplashPhoto?
	var searchCell:SearchCollectionReusableView?
	
	// MARK: UIViewController
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		
		// Navigation bar customization
		if let helveticaNeueThin:UIFont = UIFont(name: "HelveticaNeue-Thin", size: 20) {
			self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: helveticaNeueThin]
		}
		
		// Customization & setting refresher
		self.refresher.tintColor = UIColor.gray
		self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
		self.refresher.addTarget(self, action: #selector(UnsplashLibraryCollectionViewController.reloadPhotos), for: UIControlEvents.valueChanged)
		self.collectionView?.addSubview(self.refresher)
		
		// Start refreshing
		self.refresher.beginRefreshing()
		
		// First reload
		self.reloadPhotos()
		
		// Add observer
		NotificationCenter.default.addObserver(self, selector: #selector(UnsplashLibraryCollectionViewController.refreshCollection), name: PhotoIsFavoriteDidChangeNotification, object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return unsplashPhotos.count
    }
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		
		if (kind == UICollectionElementKindSectionHeader) {
			let headerView:SearchCollectionReusableView =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SearchCollectionViewHeader", for: indexPath) as! SearchCollectionReusableView
			
			self.searchCell = headerView
		} else {
			self.searchCell = SearchCollectionReusableView()
		}
		
		return self.searchCell!
		
	}

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "unsplashPhotoCell", for: indexPath) as! UnsplashPhotoCollectionViewCell
    
        // Configure the cell
		cell.set(photo: self.unsplashPhotos[indexPath.row])
		
        return cell
    }
	
	override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		
		if let cell = cell as? UnsplashPhotoCollectionViewCell {
			cell.recycle()
		}
		
	}
	
    // MARK: UICollectionViewDelegate

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		self.selectedPhoto = self.unsplashPhotos[indexPath.row]
		
		self.performSegue(withIdentifier: "goToDetail", sender: self)
		
	}

	// MARK: IBActions
	
	@IBAction func goToUnsplashWeb(_ sender: Any) {
		if let url:URL = URL(string: "https://unsplash.com"){
			if !UIApplication.shared.openURL(url) {
				print("Failed to open url: \(url.description)")
			}
		}
	}
	
	//MARK: - SEARCH
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		if(!(searchBar.text?.isEmpty)!){
			self.unsplashPhotos = self.library.search(byAuthorWith: searchBar.text)
			self.collectionView?.reloadData()
		}
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		if(searchText.isEmpty){
			//reload your data source if necessary
			self.unsplashPhotos = self.library.search(byAuthorWith: searchBar.text)
			self.collectionView?.reloadData()
		}
	}
	
	// MARK: Function
	
	func refreshCollection() {
		self.collectionView?.reloadData()
	}
	
	func reloadPhotos() {
		
		if self.refresher.isRefreshing {
			self.refresher.attributedTitle = NSAttributedString(string: "Updating...")
		}
		
		// Remove all photos
		self.library.removeAll()
		
		let downloader:Downloader = Downloader(configuration: .default, delegateQueue: .main)
		
		downloader.download(fromURL: URL(string:"https://unsplash.it/list")!, progressHandler: nil) {
			(data:Data?, response:URLResponse?, error:Error?) in
			
			if let data:Data = data, error == nil {
				
				do {
					let json = try load(fromData: data)
					for dict in json {
						self.library.append(newPhoto: try decode(unsplashPhoto: dict))
					}
					
					self.library.sort()
					
					self.unsplashPhotos = self.library.search(byAuthorWith: self.searchCell?.searchBar.text)
					
					self.collectionView?.reloadData()
					
				} catch {
					
					self.displayAlert("Error processing response", message: "The server response was different than expected.")
					
				}
				
			} else {
				
				// Error connecting to server
				let titleError:String = "Error connecting to server"
				
				if let error:Error = error {
					self.displayAlert(titleError, message: error.localizedDescription)
				} else {
					
					self.displayAlert(titleError, message: "An unknown error occurred")
					
				}
				
			}
			
			if self.refresher.isRefreshing {
				self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
				self.refresher.endRefreshing()
			}
			
		}
		
	}
	
	func displayAlert(_ title:String, message:String){
		
		// Show alert with UIAlertController
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
			(action) -> Void in
			alert.dismiss(animated: true, completion: nil)
		}))
		self.present(alert, animated: true, completion: nil)
		
	}
	
	// MARK: Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using [segue destinationViewController].
		// Pass the selected object to the new view controller.
		
		if segue.identifier == "goToDetail" {
			let destination:PhotoDetailViewController = segue.destination as! PhotoDetailViewController
			destination.photo = self.selectedPhoto
		}
		
	}
	
}
