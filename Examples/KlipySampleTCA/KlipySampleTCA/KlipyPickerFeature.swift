//
//  KlipyPickerFeature.swift
//  KlipySampleTCA
//
//  Created by Cortland Walker on 11/24/25.
//

import Foundation
import ComposableArchitecture
import KlipyCore

@Reducer
public struct KlipyPickerFeature {
    @ObservableState
    public struct State: Equatable {
        var selectedMediaUrl: String?
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeTapped
        case mediaSelected(KlipyMedia)
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .closeTapped:
                return .none
            case .mediaSelected(_):
                return .none
            }
        }
    }
}
