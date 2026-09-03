import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let mobileIdChannelName = "com.un.mobile/mobile_id"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return false
        }

        let mobileIdChannel = FlutterMethodChannel(
            name: mobileIdChannelName,
            binaryMessenger: controller.binaryMessenger
        )

        mobileIdChannel.setMethodCallHandler { [weak self] (
            call: FlutterMethodCall,
            result: @escaping FlutterResult
        ) in

            guard let self = self else {
                result(
                    FlutterError(
                        code: "APP_DELEGATE_UNAVAILABLE",
                        message: "AppDelegate não está disponível.",
                        details: nil
                    )
                )
                return
            }

            switch call.method {

            case "getNativeId":

                do {
                    let nativeId = try self.getPersistentDeviceId()

                    result(nativeId)

                } catch let error as MobileIdError {

                    result(
                        FlutterError(
                            code: "MOBILE_ID_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        )
                    )

                } catch {

                    result(
                        FlutterError(
                            code: "MOBILE_ID_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        )
                    )
                }

            default:

                result(
                    FlutterMethodNotImplemented
                )
            }
        }

        GeneratedPluginRegistrant.register(
            with: self
        )

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    // MARK: - Persistent Device ID

    private func getPersistentDeviceId() throws -> String {

        // --------------------------------------------------------
        // 1. Primeiro tenta recuperar o ID salvo no Keychain
        // --------------------------------------------------------

        if let savedId = KeychainHelper.load(
            key: "com.un.mobile.device_id"
        ) {

            if !savedId.isEmpty {
                return savedId
            }
        }

        // --------------------------------------------------------
        // 2. Se não existe no Keychain,
        //    obtém o identifierForVendor
        // --------------------------------------------------------

        guard let identifierForVendor =
                UIDevice.current.identifierForVendor?.uuidString
        else {

            throw MobileIdError.identifierUnavailable
        }

        // --------------------------------------------------------
        // 3. Salva o identifierForVendor no Keychain
        // --------------------------------------------------------

        let saved = KeychainHelper.save(
            value: identifierForVendor,
            key: "com.un.mobile.device_id"
        )

        if !saved {
            throw MobileIdError.keychainSaveFailed
        }

        // --------------------------------------------------------
        // 4. Retorna o identificador
        // --------------------------------------------------------

        return identifierForVendor
    }
}


// MARK: - Mobile ID Error

enum MobileIdError: LocalizedError {

    case identifierUnavailable
    case keychainSaveFailed

    var errorDescription: String? {

        switch self {

        case .identifierUnavailable:

            return "Não foi possível obter o identificador do aparelho."

        case .keychainSaveFailed:

            return "Não foi possível salvar o identificador no Keychain."
        }
    }
}


// MARK: - Keychain Helper

final class KeychainHelper {

    private init() {}

    // MARK: Save

    @discardableResult
    static func save(
        value: String,
        key: String
    ) -> Bool {

        guard let data = value.data(using: .utf8) else {
            return false
        }

        // --------------------------------------------------------
        // Primeiro tenta atualizar um item existente
        // --------------------------------------------------------

        let query: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrAccount as String:
                key
        ]

        let attributes: [String: Any] = [

            kSecValueData as String:
                data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return true
        }

        // --------------------------------------------------------
        // Se não existia, cria um novo item
        // --------------------------------------------------------

        let addQuery: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrAccount as String:
                key,

            kSecValueData as String:
                data,

            // O item fica disponível após o primeiro
            // desbloqueio do aparelho.
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let addStatus = SecItemAdd(
            addQuery as CFDictionary,
            nil
        )

        return addStatus == errSecSuccess
    }


    // MARK: Load

    static func load(
        key: String
    ) -> String? {

        let query: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrAccount as String:
                key,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess else {
            return nil
        }

        guard let data = result as? Data else {
            return nil
        }

        return String(
            data: data,
            encoding: .utf8
        )
    }


    // MARK: Delete

    @discardableResult
    static func delete(
        key: String
    ) -> Bool {

        let query: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrAccount as String:
                key
        ]

        let status = SecItemDelete(
            query as CFDictionary
        )

        return status == errSecSuccess ||
               status == errSecItemNotFound
    }
}