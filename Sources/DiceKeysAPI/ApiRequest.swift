//
//  File.swift
//  
//
//  Created by Stuart Schechter on 2020/11/15.
//

import Foundation


func base64urlDecode(_ base64url: String) -> Data? {
    var base64 = base64url
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    if base64.count % 4 != 0 {
        base64.append(String(repeating: "=", count: 4 - base64.count % 4))
    }
    return Data(base64Encoded: base64)
}

func base64urlEncode(_ data: Data) -> String {
    return data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

enum AuthenticationRequirementIn {
    case DerivationOptions
    case UnsealingInstructions
}

enum RequestException: Error {
    case InvalidPackagedSealedMessage
    case ParameterNotFound(String)
    case ClientNotAuthorized(AuthenticationRequirementIn)
    case ComamndRequiresDerivationOptionsWithClientMayRetrieveKeySetToTrue
}


struct PackagedSealedMessageJsonObject: Decodable {
    var derivationOptionsJson: String
    var ciphertext: String
    var unsealingInstructions: String?
    
    static func from(json: Data) -> PackagedSealedMessageJsonObject? {
        return try! JSONDecoder().decode(PackagedSealedMessageJsonObject.self, from: json)
    }

    static func from(json: String) -> PackagedSealedMessageJsonObject? {
        return from(json: json.data(using: .utf8)!)
    }
}


let ClientMayRetrieveKeySetToTrue = Set<ApiCommand>([
    ApiCommand.getSymmetricKey,
    ApiCommand.getUnsealingKey,
    ApiCommand.getSigningKey
])

protocol ApiRequest {
    var command: ApiCommand { get }
    var derivationOptions: DerivationOptions { get }
    var derivationOptionsJson: String? { get }

    func throwIfNotAuthorized(requestContext: RequestContext) throws -> Void
}

extension ApiRequest {
    func throwIfNotAuthorized(requestContext: RequestContext) throws {
        guard (!ClientMayRetrieveKeySetToTrue.contains(self.command) || derivationOptions.clientMayRetrieveKey == true) else {
            throw RequestException.ComamndRequiresDerivationOptionsWithClientMayRetrieveKeySetToTrue
        }
        guard (requestContext.satisfiesAuthenticationRequirements(
            of: derivationOptions,
            allowNullRequirement:
                // Okay to have null/empty derivationOptionsJson, with no authentication requirements, when getting a sealing key
                (self.command == ApiCommand.getSealingKey && (derivationOptionsJson == nil || derivationOptionsJson == ""))
        )) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.DerivationOptions)
        }
    }
}

func requireParameterFactory(parameters: Dictionary<String, String?>) -> (_ fieldName: String) throws -> String {
    return { (fieldName: String) throws -> String in
        let value = parameters[fieldName] ?? nil
        if let nonNilValue: String = value {
            return nonNilValue
        } else {
            throw RequestException.ParameterNotFound(fieldName)
        }
    }
}

class UrlParameters {
    let parameters: Dictionary<String, String?>
    
    init(url: URL) {
        var queryDictionary = [String: String?]()
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for queryItem in queryItems {
                queryDictionary[queryItem.name] = queryItem.value
            }
        }
        self.parameters = queryDictionary
    }
    
    func optionalField(name fieldName: String) -> String? {
        return parameters[fieldName] ?? nil
    }
    func requiredField(name fieldName: String) throws -> String {
        let value = parameters[fieldName] ?? nil
        guard let nonNilValue = value else {
            throw RequestException.ParameterNotFound(fieldName)
        }
        return nonNilValue
    }
    
}

class BaseApiRequest {
    let derivationOptions: DerivationOptions
    @objc let derivationOptionsJson: String?
    @objc let derivationOptionsJsonMayBeModified: Bool

    init(derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool = false) {
        self.derivationOptionsJson = derivationOptionsJson
        self.derivationOptionsJsonMayBeModified = derivationOptionsJsonMayBeModified == true
        self.derivationOptions = derivationOptionsJson == nil ? DerivationOptions() : DerivationOptions.fromJson(derivationOptionsJson!) ?? DerivationOptions()
    }
    
    init(urlParameters: UrlParameters) throws {
        self.derivationOptionsJson = urlParameters.optionalField(name: #keyPath(BaseApiRequest.derivationOptionsJson))
        self.derivationOptionsJsonMayBeModified = urlParameters.optionalField(name: #keyPath(BaseApiRequest.derivationOptionsJsonMayBeModified)) == "true"
        self.derivationOptions = derivationOptionsJson == nil ? DerivationOptions() : DerivationOptions.fromJson(derivationOptionsJson!) ?? DerivationOptions()
    }
}


class ApiRequestGetPassword: BaseApiRequest {
    let command: ApiCommand = ApiCommand.getPassword
}

class ApiRequestGetSecret: BaseApiRequest {
    let command: ApiCommand = ApiCommand.getSecret
}

class ApiRequestSealWithSymmetricKey: BaseApiRequest {
    let command: ApiCommand = ApiCommand.sealWithSymmetricKey
    @objc let plaintext: Data

    init(derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool = false, plaintext: Data) throws {
        self.plaintext = plaintext
        super.init(derivationOptionsJson: derivationOptionsJson, derivationOptionsJsonMayBeModified: derivationOptionsJsonMayBeModified)
    }
    
    override init(urlParameters: UrlParameters) throws {
        self.plaintext = base64urlDecode(try! urlParameters.requiredField(name: #keyPath(ApiRequestSealWithSymmetricKey.plaintext)))!
        try! super.init(urlParameters: urlParameters)
//        self.init(
//            derivationOptionsJson: urlParameters.optionalField(name: #keyPath(BaseApiRequest.derivationOptionsJson)),
//            derivationOptionsJsonMayBeModified: urlParameters.optionalField(name: #keyPath(BaseApiRequest.derivationOptionsJsonMayBeModified)) == "true"
//        )
    }
}


class ApiUnsealingRequest: BaseApiRequest, ApiRequest {
    let command: ApiCommand
    let packagedSealedMessage: PackagedSealedMessageJsonObject
    let packagedSealedMessageJson: String
    let unsealingInstructions: UnsealingInstructions?
    
    init(command: ApiCommand, packagedSealedMessageJson: String) throws {
        self.command = command
        self.packagedSealedMessageJson = packagedSealedMessageJson
        guard let packagedSealedMessage = PackagedSealedMessageJsonObject.from(json: packagedSealedMessageJson) else {
            throw RequestException.InvalidPackagedSealedMessage
        }
        self.packagedSealedMessage = packagedSealedMessage
        if let unsealingInstructionsJson = packagedSealedMessage.unsealingInstructions {
            self.unsealingInstructions = UnsealingInstructions.fromJson(unsealingInstructionsJson)
        } else {
            self.unsealingInstructions = nil
        }
        super.init(derivationOptionsJson: self.packagedSealedMessage.derivationOptionsJson)
    }
    
    func throwIfNotAuthorized(requestContext: RequestContext) throws {
        
        guard (requestContext.satisfiesAuthenticationRequirements(
            of: derivationOptions,
            allowNullRequirement:
                // Okay to have no authentication requiements in derivation options if the unsealing instructions have authentiation requirements
                (self.command == ApiCommand.unsealWithUnsealingKey && unsealingInstructions?.allow != nil)
        )) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.DerivationOptions)
        }
        if let unsealingInstructions = self.unsealingInstructions {
            guard (requestContext.satisfiesAuthenticationRequirements(of: unsealingInstructions, allowNullRequirement: true)) else {
                throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.UnsealingInstructions)
            }
        }
    }
}
