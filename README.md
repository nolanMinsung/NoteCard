![image](https://github.com/user-attachments/assets/370e98a0-b73d-4c83-8d59-5f0500d59ee5)

# NoteCard를 소개합니다.

## NoteCard는 단순한 기능만을 제공하여 직관적이고 사용이 편리한 **메모 앱**입니다.

- **[[앱스토어 링크(AppStore)]](https://apps.apple.com/us/app/notecard-simplest-memo-app/id6476649092)**
- **[주요 기능]**
    - 디자인: 메모들을 **카드 모양**으로 저장하여 언제 어디서든 메모를 작성 및 수정할 수 있습니다. 깔끔하고 직관적인 디자인을 구현하였습니다.
    - 메모 분류: 여러 카테고리를 설정하고, 메모에서 **여러 카테고리를 태그**할 수 있습니다. 카테고리별로 태그된 메모들을 확인할 수도 있습니다. 보다 편리하게 메모를 정리하고 구분해 보세요! 중요한 메모는 '즐겨찾기'로 지정하여 따로 분류할 수도 있습니다.
    - 메모 검색: 내가 찾고 싶은 메모를 바로 확인하고 싶을 때, 메모를 **검색**해 보세요! 검색하고자 하는 검색어를 입력하기만 하면 됩니다!
    - 사진 추가: 글만으로는 부족할 때! 메모에 **사진을 추가**할 수 있습니다. 앨범에서 사진을 가져올 수 있습니다. (메모 당 최대 10장)
    - 테마 색: 메모의 **테마 색**을 변경할 수 있습니다. 취향에 따라 다양한 테마 색을 적용해 보세요!
    - 다크 모드: NoteCard는 **다크 모드**를 지원합니다. 취향에 따라 **라이트 모드/다크 모드 여부를 설정**할 수 있습니다.
- **개인정보 처리방침 (Privacy Policy)**
    
    [NoteCard 개인정보 처리방침(한국어)](https://www.notion.so/NoteCard-0273910b31a84d4aafdd52f4e9e82fc2?pvs=21)
    
    [Privacy Policy for NoteCard App(English)](https://www.notion.so/Privacy-Policy-for-NoteCard-App-English-c5d86d3068a846a2a81f48eff8433172?pvs=21)
    
- **연락처(Contanct)**
    
    애플리케이션과 관련한 문의가 있다면, 언제든 다음 연락처로 문의 바랍니다. 
    
    이메일: mskim4048@naver.com

## 스크린샷

| <img width="200" alt="image" src="https://github.com/user-attachments/assets/76a7724f-5ab5-433a-a1e7-28c6322efbdc" />|<img width="200" alt="image" src="https://github.com/user-attachments/assets/5554162f-806f-4037-ae0b-0154ff052d67" />| <img width="200" alt="image" src="https://github.com/user-attachments/assets/cd3d6de4-1e75-4693-bd21-93bd7f7a87e7" />| <img width="200" alt="image" src="https://github.com/user-attachments/assets/de2c3630-b4b8-402c-98c9-2e8a46510fc6" />|<img width="200" alt="image" src="https://github.com/user-attachments/assets/618f9955-da4b-4bcc-9f10-473e0a619e0a" />|
|:-:|:-:|:-:|:-:|:-:|
| | | | | |

## 주요 구현 사항

- **Combine**: `Combine` 프레임워크를 사용하여 비동기 이벤트 및 데이터 흐름을 반응형 처리
- **Core Data Migration**: Core Data Lightweight Migration을 통한 데이터베이스 버전 관리
- **Custom Design System**: `Assets`의 Color Set과 `UIColor` Extension을 활용하여 커스텀 디자인 시스템 구축 및 이를 통해 다크 모드/라이트 모드 지원
- **Localization**: 다국어 지원(한국어, 영어)

## 기술 스택 및 아키텍처
- **Architecture**: Clean Architecture를 지향
    - Presentation, Application, Domain, Data의 4가지 주요 레이어로 구성되어 의존성 규칙 준수
- **UI**: UIKit(codebase)
- **Data Persistence**: Core Data
- **Asynchronous**: Combine
- **Language**: Swift
