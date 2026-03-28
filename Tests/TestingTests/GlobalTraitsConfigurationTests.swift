//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

@testable @_spi(ForToolsIntegrationOnly) import Testing

@Suite("GlobalTraitsConfiguration Tests")
struct GlobalTraitsConfigurationTests {
  @Test("Global traits are decoded from JSON")
  func decoding() throws {
    let json = #"{"globalTraits":{"tags":["ci","smoke"],"serialized":true,"defaultTimeLimit":{"seconds":30},"maximumTimeLimit":{"minutes":5}}}"#
    let args = try JSON.decode(__CommandLineArguments_v0.self, from: Array(json.utf8))

    let globalTraits = try #require(args.globalTraits)
    #expect(globalTraits.tags == ["ci", "smoke"])
    #expect(globalTraits.serialized == true)
    #expect(globalTraits.defaultTimeLimit?.seconds == 30)
    #expect(globalTraits.maximumTimeLimit?.minutes == 5)
  }

  @Test("Missing globalTraits field does not cause decoding failure")
  func missingGlobalTraits() throws {
    let json = #"{"parallel":true}"#
    let args = try JSON.decode(__CommandLineArguments_v0.self, from: Array(json.utf8))
    #expect(args.globalTraits == nil)
  }

  @Test("Global default time limit maps to configuration fallback")
  func defaultTimeLimit() throws {
    var args = __CommandLineArguments_v0()
    args.globalTraits = GlobalTraitsConfiguration(
      defaultTimeLimit: .init(seconds: 30)
    )
    let configuration = try configurationForEntryPoint(from: args)
    #expect(configuration.defaultTestTimeLimit == .seconds(30))
  }

  @Test("Global maximum time limit maps to configuration cap")
  func maximumTimeLimit() throws {
    var args = __CommandLineArguments_v0()
    args.globalTraits = GlobalTraitsConfiguration(
      maximumTimeLimit: .init(minutes: 1)
    )
    let configuration = try configurationForEntryPoint(from: args)
    #expect(configuration.maximumTestTimeLimit == .seconds(60))
  }

  @Test("Global serialized disables parallelization")
  func serialized() throws {
    var args = __CommandLineArguments_v0()
    args.globalTraits = GlobalTraitsConfiguration(serialized: true)
    let configuration = try configurationForEntryPoint(from: args)
    #expect(!configuration.isParallelizationEnabled)
  }

  @Test("Global serialized false preserves default parallelization")
  func notSerialized() throws {
    var args = __CommandLineArguments_v0()
    args.globalTraits = GlobalTraitsConfiguration(serialized: false)
    let configuration = try configurationForEntryPoint(from: args)
    #expect(configuration.isParallelizationEnabled)
  }

  @Test("JSONDuration resolves minutes over seconds")
  func durationResolutionMinutes() {
    let duration = GlobalTraitsConfiguration.JSONDuration(seconds: 30, minutes: 2)
    #expect(duration.resolve() == .seconds(120))
  }

  @Test("JSONDuration resolves seconds when no minutes")
  func durationResolutionSeconds() {
    let duration = GlobalTraitsConfiguration.JSONDuration(seconds: 45)
    #expect(duration.resolve() == .seconds(45))
  }

  @Test("JSONDuration resolves nil when empty")
  func durationResolutionNil() {
    let duration = GlobalTraitsConfiguration.JSONDuration()
    #expect(duration.resolve() == nil)
  }

  @Test("Empty globalTraits object does not modify configuration")
  func emptyGlobalTraits() throws {
    var args = __CommandLineArguments_v0()
    args.globalTraits = GlobalTraitsConfiguration()
    let configuration = try configurationForEntryPoint(from: args)
    #expect(configuration.defaultTestTimeLimit == nil)
    #expect(configuration.maximumTestTimeLimit == nil)
    #expect(configuration.isParallelizationEnabled)
  }
}
