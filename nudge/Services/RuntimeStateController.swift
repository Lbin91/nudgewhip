// RuntimeStateController.swift
// Nudge의 런타임 상태 기계(Reducer)와 컨트롤러.
//
// 이벤트(NudgeRuntimeEvent)에 따라 상태 스냅샷을 갱신하는 불변 리듀서와
// 상태 전이 로그를 기록하는 @Observable 컨트롤러로 구성된다.
// 유휴 감시, 일시정지, 알림, 절전 등 모든 런타임 상태를 관리한다.

import Foundation
import Observation

enum NudgeRuntimeState: String, Codable, CaseIterable, Sendable {
    case limitedNoAX
    case monitoring
    case pausedManual
    case pausedWhitelist
    case alerting
    case pausedSchedule
    case suspendedSleepOrLock
}

enum NudgeContentState: String, Codable, CaseIterable, Sendable {
    case focus = "Focus"
    case idleDetected = "IdleDetected"
    case gentleNudge = "GentleNudge"
    case strongNudge = "StrongNudge"
    case recovery = "Recovery"
    case `break` = "Break"
    case remoteEscalation = "RemoteEscalation"
}

enum NudgeRuntimeEvent: Equatable, Sendable {
    case accessibilityGranted
    case accessibilityDenied
    case manualPauseEnabled
    case manualPauseDisabled
    case whitelistMatched
    case whitelistUnmatched
    case idleDeadlineReached
    case alertEscalationDeadlineReached
    case userActivityDetected
    case sleepDetected
    case wakeDetected
    case screenLocked
    case screenUnlocked
    case fastUserSwitchingStarted
    case fastUserSwitchingEnded
    case ttsFinished
    case cooldownExpired
    case scheduleWindowEntered
    case scheduleWindowExited
    case monitorStartFailed
}

struct RuntimeSnapshot: Equatable, Sendable {
    var runtimeState: NudgeRuntimeState = .limitedNoAX
    var contentState: NudgeContentState = .focus
    var accessibilityGranted = false
    var manualPauseEnabled = false
    var whitelistMatched = false
    var schedulePaused = false
    var suspended = false
    var lastInputAt: Date?
}

struct RuntimeTransitionLogEntry: Equatable, Sendable {
    let event: NudgeRuntimeEvent
    let snapshot: RuntimeSnapshot
    let occurredAt: Date
}

enum RuntimeStateReducer {
    /// 불변 리듀서. 이벤트에 따라 스냅샷에서 새 상태를 계산해 반환
    static func reduce(_ snapshot: RuntimeSnapshot, event: NudgeRuntimeEvent, at date: Date) -> RuntimeSnapshot {
        var next = snapshot
        
        switch event {
        case .accessibilityGranted:
            next.accessibilityGranted = true
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
            
        case .accessibilityDenied, .monitorStartFailed:
            next.accessibilityGranted = false
            next.runtimeState = .limitedNoAX
            next.contentState = .focus
            
        case .manualPauseEnabled:
            next.manualPauseEnabled = true
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = .break
            
        case .manualPauseDisabled:
            next.manualPauseEnabled = false
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
            
        case .whitelistMatched:
            next.whitelistMatched = true
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = next.runtimeState == .pausedWhitelist ? .focus : next.contentState
            
        case .whitelistUnmatched:
            next.whitelistMatched = false
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
            
        case .idleDeadlineReached:
            guard resolveBaseRuntimeState(from: next) == .monitoring else { return next }
            next.runtimeState = .alerting
            next.contentState = .idleDetected
            
        case .alertEscalationDeadlineReached:
            guard next.runtimeState == .alerting else { return next }
            switch next.contentState {
            case .idleDetected:
                next.contentState = .gentleNudge
            case .gentleNudge, .strongNudge:
                next.contentState = .strongNudge
            default:
                next.contentState = .gentleNudge
            }
            
        case .userActivityDetected:
            next.lastInputAt = date
            let wasAlerting = next.runtimeState == .alerting
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = wasAlerting ? .recovery : baseContentState(for: next.runtimeState)
            
        case .ttsFinished:
            guard next.runtimeState == .alerting else { return next }
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
            
        case .scheduleWindowEntered:
            next.schedulePaused = true
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
            
        case .scheduleWindowExited:
            next.schedulePaused = false
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
            
        case .cooldownExpired:
            if next.runtimeState == .monitoring && next.contentState == .recovery {
                next.contentState = .focus
            }
            
        case .sleepDetected, .screenLocked, .fastUserSwitchingStarted:
            next.suspended = true
            next.runtimeState = .suspendedSleepOrLock
            next.contentState = .focus
            
        case .wakeDetected, .screenUnlocked, .fastUserSwitchingEnded:
            next.suspended = false
            next.runtimeState = resolveBaseRuntimeState(from: next)
            next.contentState = baseContentState(for: next.runtimeState)
        }
        
        return next
    }
    
    /// 현재 플래그(절전/권한/일시정지/화이트리스트)로 기본 런타임 상태 결정
    private static func resolveBaseRuntimeState(from snapshot: RuntimeSnapshot) -> NudgeRuntimeState {
        if snapshot.suspended {
            return .suspendedSleepOrLock
        }
        
        if !snapshot.accessibilityGranted {
            return .limitedNoAX
        }
        
        if snapshot.schedulePaused {
            return .pausedSchedule
        }
        
        if snapshot.manualPauseEnabled {
            return .pausedManual
        }
        
        if snapshot.whitelistMatched {
            return .pausedWhitelist
        }
        
        return .monitoring
    }
    
    /// 런타임 상태에 대응하는 기본 콘텐츠 상태 반환
    private static func baseContentState(for runtimeState: NudgeRuntimeState) -> NudgeContentState {
        switch runtimeState {
        case .pausedManual, .pausedSchedule:
            return .break
        case .limitedNoAX, .monitoring, .pausedWhitelist, .alerting, .suspendedSleepOrLock:
            return .focus
        }
    }
}

@MainActor
@Observable
final class RuntimeStateController {
    private(set) var snapshot: RuntimeSnapshot
    private(set) var transitionLog: [RuntimeTransitionLogEntry]
    
    init(snapshot: RuntimeSnapshot? = nil, transitionLog: [RuntimeTransitionLogEntry] = []) {
        self.snapshot = snapshot ?? RuntimeSnapshot()
        self.transitionLog = transitionLog
    }
    
    /// 이벤트를 처리해 스냅샷 갱신하고 전이 로그에 기록
    func handle(_ event: NudgeRuntimeEvent, at date: Date = .now) {
        snapshot = RuntimeStateReducer.reduce(snapshot, event: event, at: date)
        transitionLog.append(RuntimeTransitionLogEntry(event: event, snapshot: snapshot, occurredAt: date))
    }
}
