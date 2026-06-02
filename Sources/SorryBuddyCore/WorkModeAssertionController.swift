import Foundation
import IOKit.pwr_mgt

public protocol WorkModeAssertionControlling: AnyObject {
    func activate() throws
    func deactivate()
}

public final class WorkModeAssertionController: WorkModeAssertionControlling {
    public typealias CreateAssertion = (_ type: String, _ reason: String, _ id: inout IOPMAssertionID) -> IOReturn
    public typealias ReleaseAssertion = (_ id: IOPMAssertionID) -> IOReturn

    private let assertionTypes: [String]
    private let reason: String
    private let createAssertion: CreateAssertion
    private let releaseAssertion: ReleaseAssertion
    private var assertionIDs: [IOPMAssertionID] = []

    public init(
        assertionTypes: [String] = [
            kIOPMAssertionTypePreventUserIdleSystemSleep as String,
            "NetworkClientActive"
        ],
        reason: String = "SorryBuddy closed-lid work mode",
        createAssertion: @escaping CreateAssertion = { type, reason, id in
            IOPMAssertionCreateWithName(
                type as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &id
            )
        },
        releaseAssertion: @escaping ReleaseAssertion = { id in
            IOPMAssertionRelease(id)
        }
    ) {
        self.assertionTypes = assertionTypes
        self.reason = reason
        self.createAssertion = createAssertion
        self.releaseAssertion = releaseAssertion
    }

    deinit {
        deactivate()
    }

    public func activate() throws {
        guard assertionIDs.isEmpty else {
            return
        }

        var createdIDs: [IOPMAssertionID] = []

        do {
            for assertionType in assertionTypes {
                var assertionID: IOPMAssertionID = 0
                let result = createAssertion(assertionType, reason, &assertionID)

                guard result == kIOReturnSuccess, assertionID != 0 else {
                    throw SorryBuddyError.powerAssertionFailed(assertionType, Int32(result))
                }

                createdIDs.append(assertionID)
            }

            assertionIDs = createdIDs
        } catch {
            createdIDs.forEach { _ = releaseAssertion($0) }
            throw error
        }
    }

    public func deactivate() {
        assertionIDs.forEach { _ = releaseAssertion($0) }
        assertionIDs.removeAll()
    }
}
