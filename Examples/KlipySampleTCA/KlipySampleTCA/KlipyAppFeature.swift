//
//  KlipyAppFeature.swift
//  KlipySampleTCA
//
//  Created by Cortland Walker on 11/24/25.
//

import Foundation
import ComposableArchitecture
import KlipyCore
import KlipyUI

@Reducer
public struct KlipyAppFeature {
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?

        var selectedMedia: KlipyMedia?
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case openPickerButtonTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable)
    public enum Destination {
        case picker(KlipyPickerFeature)
    }

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .openPickerButtonTapped:
                state.destination = .picker(.init())
                return .none

            case let .destination(.presented(.picker(.mediaSelected(media)))):
                state.selectedMedia = media
                state.destination = nil
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
