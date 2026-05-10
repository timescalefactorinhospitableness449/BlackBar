import Foundation
import Security

@MainActor
final class UpdateStatus {
    static let disabled = UpdateStatus()
    var isUpdateReady: Bool

    init(isUpdateReady: Bool = false) {
        self.isUpdateReady = isUpdateReady
    }
}

@MainActor
protocol UpdaterProviding: AnyObject {
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsUpdates: Bool { get set }
    var isAvailable: Bool { get }
    func checkForUpdates(_ sender: Any?)
}

final class DisabledUpdaterController: UpdaterProviding {
    var automaticallyChecksForUpdates = false
    var automaticallyDownloadsUpdates = false
    let isAvailable = false
    func checkForUpdates(_ sender: Any?) {}
}

#if canImport(Sparkle)
    import Sparkle

    extension SPUStandardUpdaterController: UpdaterProviding {
        var automaticallyChecksForUpdates: Bool {
            get { self.updater.automaticallyChecksForUpdates }
            set { self.updater.automaticallyChecksForUpdates = newValue }
        }

        var automaticallyDownloadsUpdates: Bool {
            get { self.updater.automaticallyDownloadsUpdates }
            set { self.updater.automaticallyDownloadsUpdates = newValue }
        }

        var isAvailable: Bool {
            true
        }
    }
#endif

@MainActor
final class SparkleController: NSObject {
    static let shared = SparkleController()

    private let defaultsKey = "autoUpdateEnabled"
    private var updater: UpdaterProviding
    let updateStatus: UpdateStatus

    override private init() {
        #if canImport(Sparkle)
            let bundleURL = Bundle.main.bundleURL
            let isBundledApp = bundleURL.pathExtension == "app"
            let isSigned = Self.isDeveloperIDSigned(bundleURL: bundleURL)
            let canUseSparkle = isBundledApp && isSigned
        #else
            let canUseSparkle = false
        #endif

        self.updateStatus = canUseSparkle ? UpdateStatus() : .disabled
        self.updater = DisabledUpdaterController()
        super.init()

        #if canImport(Sparkle)
            guard canUseSparkle else { return }

            let saved = (UserDefaults.standard.object(forKey: self.defaultsKey) as? Bool) ?? true
            let controller = SPUStandardUpdaterController(
                startingUpdater: false,
                updaterDelegate: self,
                userDriverDelegate: nil
            )
            controller.automaticallyChecksForUpdates = saved
            controller.automaticallyDownloadsUpdates = saved
            controller.startUpdater()
            self.updater = controller
        #endif
    }

    var canCheckForUpdates: Bool {
        self.updater.isAvailable
    }

    var automaticallyChecksForUpdates: Bool {
        get { self.updater.automaticallyChecksForUpdates }
        set {
            self.updater.automaticallyChecksForUpdates = newValue
            UserDefaults.standard.set(newValue, forKey: self.defaultsKey)
        }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { self.updater.automaticallyDownloadsUpdates }
        set { self.updater.automaticallyDownloadsUpdates = newValue }
    }

    func checkForUpdates() {
        guard self.canCheckForUpdates else { return }
        self.updater.checkForUpdates(nil)
    }

    private static func isDeveloperIDSigned(bundleURL: URL) -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let code = staticCode else { return false }

        var infoCF: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &infoCF) == errSecSuccess,
              let info = infoCF as? [String: Any],
              let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate],
              let leaf = certs.first else { return false }

        if let summary = SecCertificateCopySubjectSummary(leaf) as String? {
            return summary.hasPrefix("Developer ID Application:")
        }
        return false
    }
}

#if canImport(Sparkle)
    import Sparkle

    extension SparkleController: SPUUpdaterDelegate {
        nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
            Task { @MainActor in
                self.updateStatus.isUpdateReady = true
            }
        }

        nonisolated func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
            Task { @MainActor in
                self.updateStatus.isUpdateReady = false
            }
        }

        nonisolated func userDidCancelDownload(_ updater: SPUUpdater) {
            Task { @MainActor in
                self.updateStatus.isUpdateReady = false
            }
        }

        nonisolated func updater(
            _ updater: SPUUpdater,
            userDidMake choice: SPUUserUpdateChoice,
            forUpdate item: SUAppcastItem,
            state: SPUUserUpdateState
        ) {
            let downloaded = state.stage == .downloaded
            Task { @MainActor in
                switch choice {
                case .install, .skip:
                    self.updateStatus.isUpdateReady = false
                case .dismiss:
                    self.updateStatus.isUpdateReady = downloaded
                @unknown default:
                    self.updateStatus.isUpdateReady = false
                }
            }
        }
    }
#endif
