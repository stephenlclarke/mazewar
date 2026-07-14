import Foundation
import MazewarCore
@preconcurrency import MultipeerConnectivity
import Observation

@MainActor
@Observable
final class PeerSession: NSObject {
  var connectedPeerNames: [String] = []
  var isRunning = false
  var onSnapshot: ((PlayerSnapshot) -> Void)?

  private let peerID: MCPeerID
  nonisolated(unsafe) private let session: MCSession
  private let advertiser: MCNearbyServiceAdvertiser
  private let browser: MCNearbyServiceBrowser

  override init() {
    let name = Host.current().localizedName ?? "Mazewar Player"
    peerID = MCPeerID(displayName: String(name.prefix(63)))
    session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    advertiser = MCNearbyServiceAdvertiser(
      peer: peerID, discoveryInfo: nil, serviceType: "maze-war")
    browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "maze-war")
    super.init()
    session.delegate = self
    advertiser.delegate = self
    browser.delegate = self
  }

  func start() {
    guard !isRunning else { return }
    advertiser.startAdvertisingPeer()
    browser.startBrowsingForPeers()
    isRunning = true
  }

  func send(_ snapshot: PlayerSnapshot) {
    guard !session.connectedPeers.isEmpty, let data = try? JSONEncoder().encode(snapshot) else {
      return
    }
    try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
  }

  private func refreshConnectedPeers() {
    connectedPeerNames = session.connectedPeers.map(\.displayName).sorted()
  }
}

extension PeerSession: MCSessionDelegate {
  nonisolated func session(
    _ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState
  ) {
    Task { @MainActor in refreshConnectedPeers() }
  }

  nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let snapshot = try? JSONDecoder().decode(PlayerSnapshot.self, from: data) else { return }
    Task { @MainActor in onSnapshot?(snapshot) }
  }

  nonisolated func session(
    _ session: MCSession, didReceive stream: InputStream, withName streamName: String,
    fromPeer peerID: MCPeerID
  ) {}

  nonisolated func session(
    _ session: MCSession, didStartReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID, with progress: Progress
  ) {}

  nonisolated func session(
    _ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?
  ) {}
}

extension PeerSession: MCNearbyServiceAdvertiserDelegate {
  nonisolated func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    invitationHandler(true, session)
  }

  nonisolated func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error
  ) {}
}

extension PeerSession: MCNearbyServiceBrowserDelegate {
  nonisolated func browser(
    _ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
    withDiscoveryInfo info: [String: String]?
  ) {
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
  }

  nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

  nonisolated func browser(
    _ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error
  ) {}
}
