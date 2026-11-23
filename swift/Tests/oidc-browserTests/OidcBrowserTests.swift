import Testing
@testable import oidc_browser

@Suite struct OpWhoUserInfoTests {
    @Test func includesFrameFromBounds() {
        #expect(opWhoUserInfo(requesterPID: 4242, bounds: [10, 20, 810, 620])
                == ["requesterPID": "4242", "frame": "10,20,800,600"])
    }

    @Test func omitsFrameWithoutValidBounds() {
        #expect(opWhoUserInfo(requesterPID: 4242, bounds: nil) == ["requesterPID": "4242"])
        #expect(opWhoUserInfo(requesterPID: 4242, bounds: [1, 2, 3]) == ["requesterPID": "4242"])
        #expect(opWhoUserInfo(requesterPID: 4242, bounds: [10, 20, 10, 620]) == ["requesterPID": "4242"])
    }
}
