//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

/// A type describing globally-scoped traits to apply to all tests in a run.
///
/// Instances of this type are typically decoded from a JSON configuration
/// file passed to `swift test` via the `--configuration-path` argument.
/// Global traits provide a mechanism for CI/CD pipelines and platform teams
/// to enforce policies such as time limits or diagnostic tags without
/// modifying individual test source files.
///
/// ## JSON Schema
///
/// ```json
/// {
///   "globalTraits": {
///     "defaultTimeLimit": { "seconds": 30 },
///     "maximumTimeLimit": { "minutes": 5 },
///     "tags": ["ci", "nightly"],
///     "serialized": false,
///     "retryCount": 3
///   }
/// }
/// ```
@_spi(ForToolsIntegrationOnly)
public struct GlobalTraitsConfiguration: Sendable, Codable {
  /// A type representing a duration value decoded from JSON.
  ///
  /// This type supports specifying time intervals using either a
  /// `"seconds"` or `"minutes"` key.
  public struct JSONDuration: Sendable, Codable {
    /// The duration in seconds, if specified.
    public var seconds: Int?

    /// The duration in minutes, if specified.
    public var minutes: Int?

    /// Convert this JSON duration to a Swift `Duration` value.
    ///
    /// Minutes take precedence over seconds if both are specified.
    ///
    /// - Returns: The equivalent `Duration`, or `nil` if neither seconds
    ///   nor minutes was specified.
    func resolve() -> Duration? {
      if let minutes {
        return .seconds(60 * minutes)
      } else if let seconds {
        return .seconds(seconds)
      }
      return nil
    }
  }

  /// The default time limit for tests that do not specify their own.
  ///
  /// Acts as a fallback: if a test has an explicit ``TimeLimitTrait``,
  /// the test's own time limit takes precedence. Maps to
  /// ``Configuration/defaultTestTimeLimit``.
  public var defaultTimeLimit: JSONDuration?

  /// The maximum time limit to enforce on all tests.
  ///
  /// Acts as an enforcement cap: regardless of any test's own
  /// ``TimeLimitTrait``, the effective time limit will not exceed this
  /// value. Maps to ``Configuration/maximumTestTimeLimit``.
  public var maximumTimeLimit: JSONDuration?

  /// Tag names to apply to all tests additively.
  ///
  /// These tags are unioned with any tags specified on individual tests
  /// or suites. Each string is converted to a ``Tag`` using
  /// ``Tag/init(userProvidedStringValue:)``.
  public var tags: [String]?

  /// Whether to serialize execution of all tests.
  ///
  /// When `true`, all tests run one at a time. Maps to
  /// ``Configuration/isParallelizationEnabled`` being set to `false`.
  public var serialized: Bool?

  /// The number of times to retry the test plan when a failure occurs.
  ///
  /// When set, the entire test plan is retried up to this many times
  /// if any test records an issue. Maps to
  /// ``Configuration/repetitionPolicy``.
  public var retryCount: Int?
}
