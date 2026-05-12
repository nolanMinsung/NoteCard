//
//  OrderSettingManager.swift
//  NoteCard
//
//  Created by 김민성 on 10/28/25.
//

import Combine
import Foundation

@MainActor
public final class OrderSettingManager {
    
    public static let shared = OrderSettingManager()
    private init() { }
    
    private let orderSettingChangedSubject: PassthroughSubject<Void, Never> = .init()
    public var orderSettingChangedPublisher: AnyPublisher<Void, Never> {
        return orderSettingChangedSubject
            .eraseToAnyPublisher()
    }
    
    public func setOrderCriterion(_ criterion: OrderCriterion) {
        UserDefaults.standard.setValue(criterion.rawValue, forKey: UserDefaultsKeys.orderCriterion.rawValue)
        orderSettingChangedSubject.send(())
    }
    
    public func setIsOrderAscending(_ isAscending: Bool) {
        UserDefaults.standard.setValue(isAscending, forKey: UserDefaultsKeys.isOrderAscending.rawValue)
        orderSettingChangedSubject.send(())
    }
    
}
