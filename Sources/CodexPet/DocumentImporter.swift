import Foundation
import PDFKit

enum DocumentImportError: LocalizedError {
    case unreadablePDF
    case emptyDocument
    case documentTooLarge

    var errorDescription: String? {
        switch self {
        case .unreadablePDF: "PDF okunamadı. Metin içeren başka bir PDF dene."
        case .emptyDocument: "Belgede plan oluşturacak metin bulunamadı."
        case .documentTooLarge: "Belge çok uzun. En fazla 120.000 karakterlik içerik kullan."
        }
    }
}

enum DocumentImporter {
    static let maximumCharacterCount = 120_000

    static func extractText(from url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw DocumentImportError.unreadablePDF
        }

        let text = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { throw DocumentImportError.emptyDocument }
        guard text.count <= maximumCharacterCount else { throw DocumentImportError.documentTooLarge }
        return text
    }

    static func validatePastedText(_ text: String) throws -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw DocumentImportError.emptyDocument }
        guard cleaned.count <= maximumCharacterCount else { throw DocumentImportError.documentTooLarge }
        return cleaned
    }
}
