//
//  FileManager+.swift
//  NoteCard
//
//  Created by 김민성 on 8/23/25.
//

import Foundation

public extension FileManager {
    
    public enum FileStatus {
        case isDirectory
        case isFile
        case notExist
    }
    
    public func fileOrDirectoryExist(at path: URL) -> FileStatus {
        var isDirectory = ObjCBool(false)
        let isExistAtPath: Bool
        if #available(iOS 16, *) {
            isExistAtPath = fileExists(atPath: path.path(), isDirectory: &isDirectory)
        } else {
            isExistAtPath = fileExists(atPath: path.path, isDirectory: &isDirectory)
        }
        
        if isExistAtPath {
            if isDirectory.boolValue {
                return .isDirectory
            } else {
                return .isFile
            }
        } else {
            return .notExist
        }
    }
    
}
