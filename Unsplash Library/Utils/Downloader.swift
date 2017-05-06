//
//  Downloader.swift
//  Unsplash Library
//
//  Created by Francisco Solano Gómez Pino on 27/04/2017.
//  Copyright © 2017 Francisco Solano Gómez Pino. All rights reserved.
//

import Foundation
import UIKit

class Downloader: NSObject, URLSessionDelegate, URLSessionDataDelegate  {
	
	// MARK: Aliases
	
	fileprivate typealias progressClosure = (_ progress:Float)->()
	fileprivate typealias completionClosure = (_ data:Data?, _ response:URLResponse?, _ error:Error?)->()
	
	// MARK: Blocks
	
	fileprivate var progressHandler:progressClosure?
	fileprivate var completionHandler:completionClosure?
	
	// MARK: Valiables
	
	fileprivate var expectedContentLength:Int = 0
	fileprivate var session:URLSession?
	fileprivate var buffer:NSMutableData?
	fileprivate var response:URLResponse?
	fileprivate var dataTask:URLSessionDataTask?
	fileprivate var canceled:Bool = false
	
	// MARK: Contructors
	
	init(configuration:URLSessionConfiguration, delegateQueue:OperationQueue) {
		super.init()
		session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
	}
	
	// MARK: Functions
	
	public func download(fromURL URL:URL, progressHandler:((_ progress:Float)->())?, completionHandler:@escaping (_ data:Data?, _ response:URLResponse?, _ error:Error?)->()) {
		self.download(fromRequest: URLRequest(url: URL), progressHandler: progressHandler, completionHandler: completionHandler)
	}
	
	public func download(fromRequest URLRequest:URLRequest, progressHandler:((_ progress:Float)->())?, completionHandler:@escaping (_ data:Data?, _ response:URLResponse?, _ error:Error?)->()) {
		
		// Define canceled to false
		self.canceled = false
		
		// Reset buffer & Excepted content
		self.buffer = NSMutableData()
		self.expectedContentLength = 0
		
		// Set & start task
		self.dataTask = session?.dataTask(with: URLRequest)
		self.dataTask?.resume()
		
		// Save handlers
		self.progressHandler = progressHandler
		self.completionHandler = completionHandler
	}
	
	public func downloadWithCache(fromURL URL:URL, filename:String, subFolder:String, progressHandler:((_ progress:Float)->())?, completionHandler:@escaping (_ data:Data?, _ response:URLResponse?, _ error:Error?)->()) {
		self.downloadWithCache(fromRequest: URLRequest(url: URL), filename:filename, subFolder:subFolder, progressHandler: progressHandler, completionHandler: completionHandler)
	}
	
	public func downloadWithCache(fromRequest URLRequest:URLRequest, filename:String, subFolder:String, progressHandler:((_ progress:Float)->())?, completionHandler:@escaping (_ data:Data?, _ response:URLResponse?, _ error:Error?)->()) {
		
		let fileManager:FileManager = FileManager.default
		
		guard let cacheURL:URL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).last else {
			return completionHandler(nil, nil, nil)
		}
		
		let directoryURL:URL = cacheURL.appendingPathComponent(subFolder)
		let fileURL:URL = directoryURL.appendingPathComponent(filename)
		
		if !fileManager.fileExists(atPath: directoryURL.path) {
			try! fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
		}
		
		DispatchQueue.global(qos: .background).async {
			
			if fileManager.fileExists(atPath: fileURL.path) {
				
				let data:Data? = try? Data(contentsOf: fileURL)
				
				DispatchQueue.main.async {
					completionHandler(data,nil,nil)
				}
				
			} else {
				
				self.download(fromRequest: URLRequest, progressHandler: progressHandler, completionHandler: {
					(data:Data?, response:URLResponse?, error:Error?) in
					
					if let data = data, error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200 {
						if let _:UIImage = UIImage(data: data) {
							try? data.write(to: fileURL)
						}
					}
					
					DispatchQueue.main.async {
						
						completionHandler(data,response,error)
					}
					
				})
				
			}
		}
		
	}
	
	public func cancel(){
		
		// Cancel task
		self.dataTask?.cancel()
		
	}
	
	public func cancelIgnoringCompletion() {
		
		// Mark task canceled
		self.canceled = true
		
		// Cancel task
		self.cancel()
		
	}
	
	// MARK: URLSessionDataDelegate
	
	internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		self.response = response
		self.expectedContentLength = Int(response.expectedContentLength)
		completionHandler(.allow)
	}
	
	internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		self.buffer?.append(data)
		if let bufferLength = self.buffer?.length,
			let progressHandler:progressClosure = self.progressHandler {
			progressHandler(Float(bufferLength) / Float(self.expectedContentLength))
		}
	}
	
	internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let completionHandler:completionClosure = self.completionHandler,
			let buffer:Data = self.buffer as Data?,
			self.canceled == false {
			completionHandler(buffer, self.response, error)
		}
	}
	
}
