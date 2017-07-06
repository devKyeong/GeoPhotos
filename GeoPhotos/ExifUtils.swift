//
//  ExifUtils.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa
import CoreLocation

class ExifUtils {
  
  class func diagnose(_ reason:String) -> Bool {
    print("guard return at \(#line) for \(reason)")
    return true
  }
  
  class func parseFiles(_ url:URL) -> [URL]? {
    let fm = FileManager.default
    var fileUrls:[URL]?
    do {
      let directoryContents = try
        fm.contentsOfDirectory(at: url,includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
      fileUrls = directoryContents.filter({ (url) -> Bool in
        return url.isTypeRegularFile() && ImageExtensions.contains(url.pathExtension.lowercased() ?? "")
      })
    } catch let error as NSError {
      print("parseFiles:", error.localizedDescription)
    }
    return fileUrls
  }
  
  class func parseURLs(_ urls:[URL]) -> [ImageItem]{
    var images:[ImageItem] = []
    urls.forEach { (url) in
      if let image = parseURL(url) {
        images.append(image)
      }
    }
    return images
  }

  class func parseURL(_ url:URL) -> ImageItem? {
    let path = url.path
    let name = url.lastPathComponent
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
    // file attrs
    guard let type = attrs[FileAttributeKey.type] as? String else { return nil }
    guard let sizeNumber = attrs[FileAttributeKey.size] as? NSNumber else { return nil }
    let size = sizeNumber.uint64Value
    guard let createdAt = attrs[FileAttributeKey.creationDate] as? Date else { return nil }
    guard let modifiedAt = attrs[FileAttributeKey.modificationDate] as? Date else { return nil }
    // image properties
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    guard let propertiesValue = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) else { return nil }
    guard let properties = propertiesValue as? NSDictionary else { return nil }
    guard let width = properties[kCGImagePropertyPixelWidth as String] as? Int else { return nil }
    guard let height = properties[kCGImagePropertyPixelHeight as String] as? Int else { return nil }
    let dimension = NSSize(width: width, height: height)
    
    let item = ImageItem(url: url,
                         type: type,
                         name: name,
                         size: size,
                         dimension: dimension,
                         createdAt: createdAt,
                         modifiedAt: modifiedAt)
    item.mimeType = CGImageSourceGetType(imageSource) as String?
    item.updateProperties(properties)
    return item
    
  }
  
  class func formatDegreeValue(_ degree: Double, latitude:Bool) -> String {
    var seconds = Int(degree * 3600)
    let degrees = seconds / 3600
    seconds = abs(seconds % 3600)
    let minutes = seconds / 60
    seconds %= 60
    let direction:String
    if latitude {
      direction = degrees > 0 ? "N" : "S"
    }else {
      direction = degrees > 0 ? "E" : "W"
    }
    return "\(abs(degrees))°\(minutes)'\(seconds)\" \(direction)"
  }
  
  class func formatCoordinate(_ coordinate:CLLocationCoordinate2D) -> String {
    var latSeconds = Int(coordinate.latitude * 3600)
    let latDegrees = latSeconds / 3600
    latSeconds = abs(latSeconds % 3600)
    let latMinutes = latSeconds / 60
    latSeconds %= 60
    var longSeconds = Int(coordinate.longitude * 3600)
    let longDegrees = longSeconds / 3600
    longSeconds = abs(longSeconds % 3600)
    let longMinutes = longSeconds / 60
    longSeconds %= 60
    return "\(abs(latDegrees))°\(latMinutes)'\(latSeconds)\"\(latDegrees >= 0 ? "N" : "S") \(abs(longDegrees))°\(longMinutes)'\(longSeconds)\"\(longDegrees >= 0 ? "E" : "W")"
  }

  
}
