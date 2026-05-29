import Foundation

public struct ShellCommand: Equatable, Sendable {
    public let executable: String
    public let arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }
}

public protocol ShellRunning: AnyObject {
    @discardableResult
    func run(_ command: ShellCommand) throws -> String
}

public final class SystemShellClient: ShellRunning {
    public init() {}

    @discardableResult
    public func run(_ command: ShellCommand) throws -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: output, encoding: .utf8) ?? ""
        let errorText = String(data: errorOutput, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw ShellError.failed(
                executable: command.executable,
                status: process.terminationStatus,
                output: outputText,
                error: errorText
            )
        }

        return outputText
    }
}

public struct ShellError: Error, Equatable {
    public let executable: String
    public let status: Int32
    public let output: String
    public let error: String

    public static func failed(executable: String, status: Int32, output: String, error: String) -> ShellError {
        ShellError(executable: executable, status: status, output: output, error: error)
    }
}
