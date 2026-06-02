import IOKit.pwr_mgt
import Testing
@testable import SorryBuddyCore

struct WorkModeAssertionControllerTests {
    @Test func activateCreatesEachConfiguredAssertionOnce() throws {
        var createdTypes: [String] = []
        var nextID: IOPMAssertionID = 10
        let controller = WorkModeAssertionController(
            assertionTypes: ["PreventUserIdleSystemSleep", "NetworkClientActive"],
            createAssertion: { type, _, id in
                createdTypes.append(type)
                id = nextID
                nextID += 1
                return kIOReturnSuccess
            },
            releaseAssertion: { _ in kIOReturnSuccess }
        )

        try controller.activate()
        try controller.activate()

        #expect(createdTypes == ["PreventUserIdleSystemSleep", "NetworkClientActive"])
    }

    @Test func deactivateReleasesActiveAssertions() throws {
        var releasedIDs: [IOPMAssertionID] = []
        var nextID: IOPMAssertionID = 30
        let controller = WorkModeAssertionController(
            assertionTypes: ["A", "B"],
            createAssertion: { _, _, id in
                id = nextID
                nextID += 1
                return kIOReturnSuccess
            },
            releaseAssertion: { id in
                releasedIDs.append(id)
                return kIOReturnSuccess
            }
        )

        try controller.activate()
        controller.deactivate()
        controller.deactivate()

        #expect(releasedIDs == [30, 31])
    }

    @Test func activateRollsBackAlreadyCreatedAssertionsWhenLaterAssertionFails() {
        var releasedIDs: [IOPMAssertionID] = []
        let controller = WorkModeAssertionController(
            assertionTypes: ["A", "B"],
            createAssertion: { type, _, id in
                if type == "B" {
                    return 1
                }

                id = 44
                return kIOReturnSuccess
            },
            releaseAssertion: { id in
                releasedIDs.append(id)
                return kIOReturnSuccess
            }
        )

        #expect(throws: SorryBuddyError.powerAssertionFailed("B", 1)) {
            try controller.activate()
        }
        #expect(releasedIDs == [44])
    }
}
