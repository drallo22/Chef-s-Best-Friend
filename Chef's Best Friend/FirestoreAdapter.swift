import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreAdapter {
    private var db: Firestore

    init() {
        self.db = Firestore.firestore()
    }

    // Add a new document with a specific ID or let Firestore auto-generate the ID
    // Add a new document with the name of the recipe as the document ID
    func addDocument<T: Codable>(
        collectionName: String,
        model: T,
        completion: @escaping (Result<DocumentReference, Error>) -> Void
    ) {
        do {
            // Extract the name property from the model (assuming it has a 'name' property)
            guard let recipeName = (model as? Recipe)?.name else {
                // Handle the case where the model doesn't have a 'name' property
                let error = NSError(domain: "YourDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Recipe model must have a 'name' property."])
                completion(.failure(error))
                return
            }

            // Use the recipe name as the document ID
            let reference = try db.collection(collectionName).document(recipeName)

            // Set the document data
            try reference.setData(from: model) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(reference)) // Success
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }


    // Create or set a document
    func setDocument<T: Codable>(collectionName: String,
                                 documentId: String,
                                 model: T,
                                 completion: @escaping (Error?) -> Void) {

        do {
            let _ = try db.collection(collectionName).document(documentId).setData(from: model) { error in

                completion(error)
            }
        } catch let error {
            completion(error)
        }
    }

    // Fetch a single document by ID
    func getDocument<T: Codable>(collectionName: String,
                                 documentId: String,
                                 completion: @escaping (Result<T, Error>) -> Void) {

        let docRef = db.collection(collectionName).document(documentId)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let result = Result {
                    try document.data(as: T.self)
                }

                switch result {
                    case .success(let data):
                        completion(.success(data)) // Success
                    case .failure(let error):
                        completion(.failure(error))
                    }
            } else {
                completion(.failure(error ?? FirestoreError.noDocument))
            }
        }
    }

    // Update a document
    func updateDocument(collectionName: String,
                        documentId: String,
                        fields: [String: Any],
                        completion: @escaping (Error?) -> Void) {

        let docRef = db.collection(collectionName).document(documentId)
        docRef.updateData(fields) { error in
            if let error = error {
                print("Error updating document \(documentId): \(error)")
            } else {
                print("Document \(documentId) updated successfully.")
            }
            completion(error)
        }
    }


    // Delete a document
    func deleteDocument(collectionName: String,
                        documentId: String,
                        completion: @escaping (Error?) -> Void) {

        db.collection(collectionName).document(documentId).delete() { error in
            completion(error)
        }
    }

    typealias DocumentSnapshots = [QueryDocumentSnapshot]

    // Get all documents from a specific collection
    func getDocuments(
        collectionName: String,
        completion: @escaping (Result<DocumentSnapshots, Error>) -> Void
    ) {
        db.collection(collectionName).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let documents = querySnapshot?.documents {
                completion(.success(documents)) // Success
            } else {
                completion(.failure(FirestoreError.noDocument))
            }
        }
    }

    typealias CollectionDocuments = [String: DocumentSnapshots]

    // TODO: Add more functionalities such as query operations with
    // filters, sorting, pagination, etc.
}

enum FirestoreError: Error {
    case noDocument
}
