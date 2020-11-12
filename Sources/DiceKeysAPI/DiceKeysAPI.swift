import Foundation

struct DiceKeysAPI {
    var text = "Hello, World!"
}

struct WebBasedApplicationIdentity: Codable {
 /**
 * The host, which is the same as a hostname unless a non-standard https port is used (not recommended).
 * Start it with a "*." to match a domain and any of its subdomains.
 *
 * > origin = <scheme> "://" <hostname> [ ":" <port> ] = <scheme> "://" <host> = "https://" <host>
 * So, `host = origin.substr(8)`
 */
    var host: String
    var paths: [String]?
}


protocol AuthenticationRequirements {
  /**
   * On Apple platforms, applications are specified by a URL containing a domain name
   * from the Internet's Domain Name System (DNS).
   *
   * If this value is specified, applications must come from clients that have a URL prefix
   * starting with one of the items on this list if they are to use a derived key.
   *
   * Since some platforms, including iOS, do not allow the DiceKeys app to authenticate
   * the sender of an API request, the app may perform a cryptographic operation
   * only if it has been instructed to send the result to a URL that starts with
   * one of the permitted prefixes.
   */
    var allow: [WebBasedApplicationIdentity]? { get set }

  /**
   * When set, clients will need to issue a handshake request to the API,
   * and receive an authorization token (a random shared secret), before
   * issuing other requests where the URL at which they received the token
   * starts with one of the authorized prefixes.
   *
   * The DiceKeys app will map the authorization token to that URL and,
   * when requests include that token, validate that the URL associated
   * with the token has a valid prefix. The DiceKeys app will continue to
   * validate that responses are also sent to a valid prefix.
   *
   */
    var requireAuthenticationHandshake: Bool? { get set }

  
  /**
   * In Android, client applications are identified by their package name,
   * which must be cryptographically signed before an application can enter the
   * Google play store.
   *
   * If this value is specified, Android apps must have a package name that begins
   * with one of the provided prefixes if they are to use a derived key.
   *
   * Note that all prefixes, and the client package names they are compared to,
   * have an implicit '.' appended to to prevent attackers from registering the
   * suffix of a package name.  Hence the package name "com.example.app" is treated
   * as "com.example.app." and the prefix "com.example" is treated as
   * "com.example." so that an attacker cannot generate a key by registering
   * "com.examplesignedbyattacker".
   */
    var allowAndroidPrefixes: [String]? { get set }
}

struct UnsealingInstructions: AuthenticationRequirements, Codable {
    var allow: [WebBasedApplicationIdentity]?
    var requireAuthenticationHandshake: Bool?
    var allowAndroidPrefixes: [String]?

    static func fromJson(_ json: Data) -> UnsealingInstructions? {
        return try! JSONDecoder().decode(UnsealingInstructions.self, from: json)
    }

    static func fromJson(_ json: String) -> UnsealingInstructions? {
        return fromJson(json.data(using: .utf8)!)
    }
}

enum HashFunction: String, Codable {
    case BLAKE2b, Argon2id
}

enum DerivationOptionsType: String, Codable {
    case Password, Secret, SigningKey, SymmetricKey, UnsealingKey
}

enum WordListName: String, Codable {
    case EN_512_words_5_chars_max_ed_4_20200917,
         EN_1024_words_6_chars_max_ed_4_20200917
}

struct DerivationOptions: AuthenticationRequirements, Codable {
    var type: DerivationOptionsType?
    
    var allow: [WebBasedApplicationIdentity]?
    var requireAuthenticationHandshake: Bool?
    var allowAndroidPrefixes: [String]?

    /**
   * A string that may be added by the DiceKeys app to help users remember which
   * seed (DiceKey) they used to derive a key or secret.
   *
   * e.g. `My DiceKey labeled "Personal Accounts".`
   */
    var seedHint: String?

  /**
   * A specific seed hint consisting of the letters at the four corners of
   * the DiceKey, in clockwise order from wherever the user initially
   * scanned as the top-left corner.
   *
   * The array must be a string consisting of four uppercase characters
   */
    var cornerLetters: String?

  /**
   * The DiceKeys app will want to get a user's consent before deriving a
   * secret on behalf of an app.
   *
   * When a user approves a set of DerivationOptions, this field
   * allows us to record that the options were, at least at one time, approved
   * by the holder of this DiceKey.
   *
   * Set this field to empty (two double quotes, ""), call DerivationOptions.derivePrimarySecret
   * with the seed (DiceKey) and these derivation options.  Take that primary secret,
   * turn it into url-safe base64, and then re-run derivePrimarySecret with that
   * base64 encoding as the seed. Insert the base64 encoding of the first 128 bits
   * into this field.  (If the derivation options derive fewer than 128 bits, use
   * whatever bits are available.)
   */
    var proofOfPriorDerivation: String?


  /**
   * Unless this value is explicitly set to _true_, the DiceKeys may prevent
   * to obtain a raw derived [[SymmetricKey]],
   * UnsealingKey, or
   * SigningKey.
   * Clients may retrieve a derived SealingKey,
   * or SignatureVerificationKey even if this value
   * is not set or set to false.
   *
   * Even if this value is set to true, requests for keys are not permitted unless
   * the client would be authorized to perform cryptographic operations on those keys.
   * In other words, access is forbidden if the [restrictions] field is set and the
   * specified [Restrictions] are not met.
   */
    var clientMayRetrieveKey: Bool?

  /**
   * When using a DiceKey as a seed, the default seed string will be a 75-character
   * string consisting of triples for each die in canonical order:
   *
   *   1 The uppercase letter on the die
   *   2 The digit on the die
   *   3 The orientation relative to the top of the square
   *
   * If  `excludeOrientationOfFaces` is set to `true` set to true,
   * the orientation character (the third member of each triple) will be
   * set to "?" before the canonical form is determined
   * (the choice of the top left corner that results in the human readable
   * form earliest in the sort order) and "?" will be the third character
   * in each triple.
   *
   * This option exists because orientations may be harder for users to copy correctly
   * than letters and digits are. With this option on, should a user choose to manually
   * copy the contents of a DiceKey and make an error in copying an orientation, that
   * error will not prevent them from re-deriving the specified key or secret.

    */
    var excludeOrientationOfFaces: Bool?
    
    
    var hashFunction: HashFunction?
    var hashFunctionMemoryLimitInBytes: Int64?
    var hashFunctionMemoryPasses: Int64?
    var lengthInBytes: Int32?
    var lengthInWords: Int32?
    var lengthInBits: Int32?
    var wordList: WordListName?
    
    static func fromJson(_ json: Data) -> DerivationOptions? {
        return try! JSONDecoder().decode(DerivationOptions.self, from: json)
    }

    static func fromJson(_ json: String) -> DerivationOptions? {
        return fromJson(json.data(using: .utf8)!)
    }
    
    func toJson() -> String {
        return try! String(decoding: JSONEncoder().encode(self), as: UTF8.self)
    }
    
}


