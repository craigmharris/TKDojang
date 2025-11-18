import Foundation
import CloudKit

/**
 * CloudKitErrorHandler.swift
 *
 * PURPOSE: Transform raw CloudKit errors into user-friendly messages
 *
 * DESIGN DECISIONS:
 * - Maps common CKError codes to actionable user messages
 * - Provides retry suggestions where appropriate
 * - Avoids exposing technical details to users
 * - Handles authentication, network, and server errors gracefully
 *
 * USAGE:
 * ```swift
 * do {
 *     try await cloudKitService.submitFeedback(...)
 * } catch {
 *     let userMessage = CloudKitErrorHandler.userFriendlyMessage(for: error)
 *     showAlert(message: userMessage)
 * }
 * ```
 */

enum CloudKitErrorHandler {

    /**
     * Converts CloudKit errors to user-friendly messages
     *
     * WHY: CloudKit errors are technical and confusing for end users
     */
    static func userFriendlyMessage(for error: Error) -> String {
        // Check if it's a CloudKit error
        guard let ckError = error as? CKError else {
            return "An unexpected error occurred. Please try again."
        }

        switch ckError.code {
        // MARK: - Authentication & Account Errors
        case .notAuthenticated:
            return """
            Please sign in to iCloud to use community features.

            Go to Settings → [Your Name] → iCloud and make sure you're signed in.
            """

        case .quotaExceeded:
            return """
            Your iCloud storage is full.

            Free up space in iCloud or upgrade your storage plan to continue.
            """

        // MARK: - Network Errors
        case .networkFailure, .networkUnavailable:
            return """
            No internet connection.

            Check your connection and try again.
            """

        case .requestRateLimited:
            return """
            Too many requests. Please wait a moment and try again.
            """

        // MARK: - Server Errors
        case .serviceUnavailable, .serverResponseLost:
            return """
            The CloudKit service is temporarily unavailable.

            Please try again in a few moments.
            """

        case .zoneBusy, .serverRejectedRequest:
            return """
            The server is busy processing your request.

            Please try again shortly.
            """

        // MARK: - Permission Errors
        case .permissionFailure:
            return """
            You don't have permission to perform this action.

            This may be a configuration issue. Please contact support if this persists.
            """

        case .participantMayNeedVerification:
            return """
            Your iCloud account needs verification.

            Please verify your account in Settings and try again.
            """

        // MARK: - Data Errors
        case .invalidArguments:
            return """
            Invalid data submitted. Please check your input and try again.
            """

        case .incompatibleVersion:
            return """
            This app version is incompatible with the current service.

            Please update to the latest version of TKDojang.
            """

        case .assetFileNotFound, .assetFileModified:
            return """
            Unable to access required data.

            Please try again or contact support if this persists.
            """

        // MARK: - Conflict Errors
        case .serverRecordChanged:
            return """
            This item was changed by someone else.

            Please refresh and try again.
            """

        case .changeTokenExpired:
            return """
            Your data is out of sync.

            Please pull to refresh and try again.
            """

        // MARK: - Batch Operation Errors
        case .batchRequestFailed:
            return """
            Some operations failed. Please try again.
            """

        // MARK: - Unknown/Generic Errors
        case .internalError, .unknownItem:
            return """
            An unexpected error occurred.

            Please try again or contact support if this persists.
            """

        // MARK: - Default Fallback
        default:
            // For any unhandled error codes, provide generic message
            return """
            Unable to complete this action.

            Please try again later. If this persists, contact support with error code: \(ckError.code.rawValue)
            """
        }
    }

    /**
     * Determines if an error is retryable
     *
     * WHY: Some errors (network, server busy) should show retry button, others shouldn't
     */
    static func isRetryable(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else {
            return true // Unknown errors are retryable
        }

        switch ckError.code {
        // Retryable errors (network, server temporary issues)
        case .networkFailure,
             .networkUnavailable,
             .serviceUnavailable,
             .serverResponseLost,
             .zoneBusy,
             .requestRateLimited,
             .serverRejectedRequest,
             .changeTokenExpired:
            return true

        // Non-retryable errors (authentication, permissions, data issues)
        case .notAuthenticated,
             .permissionFailure,
             .quotaExceeded,
             .invalidArguments,
             .incompatibleVersion,
             .participantMayNeedVerification:
            return false

        // Default to retryable
        default:
            return true
        }
    }

    /**
     * Gets suggested wait time before retry
     *
     * WHY: Rate limiting and server busy errors need backoff delays
     */
    static func suggestedRetryDelay(for error: Error) -> TimeInterval? {
        guard let ckError = error as? CKError else {
            return nil
        }

        switch ckError.code {
        case .requestRateLimited:
            return 30.0 // Wait 30 seconds

        case .zoneBusy, .serverRejectedRequest:
            return 5.0 // Wait 5 seconds

        case .serviceUnavailable, .serverResponseLost:
            return 10.0 // Wait 10 seconds

        default:
            return nil
        }
    }
}
