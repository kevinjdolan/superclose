// CommandLineOptions.swift
// Tiny parser for the handful of flags SuperClose accepts on launch (`--help`
// and `--dump`). `main.swift` builds one of these from `CommandLine.arguments`
// to decide whether to print usage, dump candidates, or open the review window.

import Foundation

struct CommandLineOptions {
    let arguments: Set<String>

    init(arguments: [String] = Array(CommandLine.arguments.dropFirst())) {
        self.arguments = Set(arguments)
    }

    var showsHelp: Bool {
        arguments.contains("--help")
    }

    var dumpsCandidates: Bool {
        arguments.contains("--dump")
    }
}

