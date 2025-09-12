//
//  ImageFileError.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import Foundation

/// 이미지 파일 처리 및 데이터 변환과 관련된 에러 타입
enum ImageFileError: NoteCardError {
    case loadingDataFromNSProviderFaild
    case loadedFromNSProviderButDataNotFound
    case imageFileExtensionError
    case dataToImageConversionFailed
    case thumbnailCreationError
    case saveError(Error)
    case imageLoadingError(Error)
    case fileNotFound
    case fileDeleteError(Error)
    case fileURLGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingDataFromNSProviderFaild:
            return "NSProvider로부터 데이터를 로딩하는 데 실패했습니다."
        case .loadedFromNSProviderButDataNotFound:
            return "NSProvider에서 데이터 로딩에는 성공했으나(erorr가 nil), 받아온 data도 없음(nil)."
        case .imageFileExtensionError:
            return "저장될 이미지 파일의 확장자를 찾을 수 없습니다."
        case .dataToImageConversionFailed:
            return "Data 인스턴스를 이미지로 변환하는 데 실패했습니다."
        case .thumbnailCreationError:
            return "썸네일 이미지를 생성하는 데 실패했습니다."
        case .saveError(let error):
            return "이미지 데이터 저장 실패. reason: \(error.localizedDescription)"
        case .imageLoadingError(let error):
            return "이미지 로딩 실패. reason: \(error.localizedDescription)"
        case .fileNotFound:
            return "이미지 파일을 찾을 수 없습니다."
        case .fileDeleteError(let error):
            return "이미지 파일을 삭제하는 데 실패했습니다. reason: \(error)"
        case .fileURLGenerationFailed:
            return "이미지 파일의 URL 생성에 실패했습니다."
        }
    }
    
    var displayingMessage: String {
        switch self {
        case .loadingDataFromNSProviderFaild, .loadedFromNSProviderButDataNotFound:
            return "이미지를 저장하는 데 실패했습니다."
        case .imageFileExtensionError:
            return "이미지 확장자 에러"
        case .dataToImageConversionFailed:
            return "이미지 파일을 표시할 수 없습니다. 파일이 손상되었을 수 있습니다."
        case .thumbnailCreationError:
            return "이미지 미리보기를 생성하는 데 실패했습니다."
        case .saveError:
            return "이미지를 기기에 저장하는 데 실패했습니다."
        case .imageLoadingError, .fileNotFound, .fileURLGenerationFailed:
            return "이미지를 불러오는 데 실패했습니다. 파일이 이동되었거나 삭제되었을 수 있습니다."
        case .fileDeleteError:
            return "이미지를 삭제하는 데 실패했습니다."
        }
    }
}
