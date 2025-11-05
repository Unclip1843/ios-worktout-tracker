import SwiftData
import OSLog

extension ModelContext {
    /// Attempts to save the context, rolling back and logging on failure.
    /// - Returns: An optional error describing why the save failed.
    @discardableResult
    func saveOrRollback(action: String, logger: Logger) -> Error? {
        do {
            try save()
            return nil
        } catch {
            logger.error("Failed to \(action): \(error.localizedDescription)")
            rollback()
            return error
        }
    }
}
