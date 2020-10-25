

import UIKit
import Foundation


public class ImageLoader {
    
    var cache = NSCache<NSString, NSData>()
    
    public class var sharedLoader : ImageLoader {
        struct Static {
            static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
    public func imageForUrl(urlString: String, completionHandler: @escaping(_ image: UIImage?, _ url: String) -> ()) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { 
            var data: NSData?
            
            if let dataCache = self.cache.object(forKey: urlString as NSString){
                data = (dataCache) as NSData
                
            }else{
                if (URL(string: urlString) != nil)
                {
                    data = NSData(contentsOf: URL(string: urlString)!)
                    if data != nil {
                        self.cache.setObject(data!, forKey: urlString as NSString)
                    }
                }else{
                    return
                }
            }
            
            if let goodData = data {
                let image = UIImage(data: goodData as Data)
                DispatchQueue.main.async(execute: {() in
                    completionHandler(image, urlString)
                })
                return
            }
            
            let downloadTask: URLSessionDataTask = URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: { (data, response, error) -> Void in
                
                if (error != nil) {
                    completionHandler(nil, urlString)
                    return
                }
                
                if data != nil {
                    let image = UIImage(data: data!)
                    self.cache.setObject(data! as NSData, forKey: urlString as NSString)
                    DispatchQueue.main.async(execute: {() in
                        completionHandler(image, urlString)
                    })
                    return
                }
            })
            downloadTask.resume()
            
        }
        
    }
}
