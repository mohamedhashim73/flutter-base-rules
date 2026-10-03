# Firebase Architecture Rules

This document defines how Firebase should be used across the application.

The goal is to ensure:
- scalable firestore usage
- reusable queries
- predictable Cubits
- clean architecture
- isolated side effects
- centralized Firebase access

---

# 1. Core Principle

Firebase access MUST be centralized through:

dart
FirebaseService


Cubit MUST NEVER directly use:

dart
FirebaseFirestore.instance


or raw firestore queries.

---

# 2. FirebaseService Responsibility

FirebaseService is responsible for:

- collection/document access
- queries
- streams
- transactions
- pagination
- scoped organization paths
- batch operations
- reusable firestore logic

FirebaseService is NOT responsible for:

- UI logic
- RequestStatus handling
- state management
- toast/snackbar handling
- feature decisions
- caching decisions

---

# 3. Cubit Responsibility

Cubit is responsible for:

- deciding fetch strategy
- deciding realtime vs one-time fetch
- mapping models
- caching
- filtering/searching
- state emission
- side effects triggering through states

---

# 4. Realtime Rule

Firestore SHOULD NOT automatically mean realtime.

Realtime listeners should ONLY be used when feature behavior actually requires live updates.

Examples:

✅ invoices dashboard  
✅ live orders  
✅ chats  
✅ stock updates  
✅ active sessions

NOT:

❌ static settings  
❌ rarely changing screens  
❌ one-time form data  
❌ lightweight details pages

---

# 5. Fetch Strategy Rule

Cubit decides whether feature uses:

## One-time fetch

dart
FirebaseService.getCollection()


OR

## Realtime listener

dart
FirebaseService.watchCollection()


based on feature requirements.

FirebaseService itself MUST NOT force realtime behavior.

---

# 6. Forbidden Rule

❌ NEVER write raw firestore queries inside Cubits.

Wrong:

dart
FirebaseFirestore.instance
    .collection('people')
    .where(...)


Correct:

dart
FirebaseService.watchCollection(...)


or

dart
FirebaseService.getCollection(...)


---

# 7. Reusable Query Rule

If firestore query logic becomes reusable:

✅ move it into FirebaseService

Example:

dart
FirebaseService.watchCollection()
FirebaseService.getCollection()
FirebaseService.updateDocument()
FirebaseService.runTransaction()


---

# 8. State Ownership Rule

FirebaseService MUST remain stateless.

Services MUST NOT hold:

- selected models
- cached feature data
- controllers
- filters
- current screen state

Those belong to Cubits only.

Correct:

dart
class PeopleCubit extends Cubit<PeopleStates> {
  final Map<String, PersonModel> _people = {};
}


Wrong:

dart
class FirebaseService {
  static Map<String, PersonModel> people = {};
}


---

# 9. Stream Architecture Rule

Realtime listeners MUST:

- use private StreamSubscription
- be cancelled inside close()
- never expose raw stream to UI

Example:

dart
StreamSubscription? _sub;


---

# 10. Cache + Firebase Rule

Cubit MAY:

- load cached data first
- attach realtime listener later
- update cache after firestore updates

Example flow:

dart
CacheManager.getPeople()
→ emit loading
→ FirebaseService.watchCollection()
→ update cache
→ emit success


---

# 11. Error Handling Rule

FirebaseService should ONLY throw/forward errors.

Cubit decides which state to emit.

State decides how feedback is shown.

Correct flow:

text
FirebaseService → Cubit → State


NOT:

text
FirebaseService → Toast/UI


---

# 12. Transactions Rule

Complex writes affecting multiple documents SHOULD use:

dart
FirebaseService.runTransaction()


instead of manual multiple updates.

This ensures:
- consistency
- rollback safety
- predictable writes

---

# 13. Pagination Rule

Pagination logic belongs to:

✅ Cubit

NOT FirebaseService.

FirebaseService only exposes query capabilities.

Cubit stores:

- last document
- hasMore
- current page state

---

# 14. Collection Names Rule

All collection names MUST be centralized inside:

dart
FirebaseCollections


Never hardcode collection names inside Cubits or UI.

Correct:

dart
FirebaseCollections.people


Wrong:

dart
'people'


---

# 15. Organization Scope Rule

Organization/user scoping MUST be handled inside FirebaseService.

Cubit should never manually build organization paths.

Correct:

dart
FirebaseService.scopedCollectionRef(...)


# 17. Document ID Injection Rule

Firestore document id SHOULD be stored inside document data itself.

Preferred pattern:

dart
final ref = scopedCollectionRef(collectionName).doc();

await ref.set({
  ...data,
  'id': ref.id,
});


NOT:

dart
collection.add(data)


unless document id is intentionally unnecessary.

---

## Why This Rule Exists

Storing document id inside model data ensures:

- easier model mapping
- predictable local cache
- simpler updates/deletes
- reusable model serialization
- easier realtime map handling
- safer filtering/searching

---

## Preferred Model Pattern

dart
class PersonModel {
  final String id;
}


instead of relying on:

dart
doc.id


everywhere across the app.

---

## Correct Add Flow

dart
static Future<String?> addDocument({
  required String collectionName,
  required Map<String, dynamic> data,
}) async {
  final ref = scopedCollectionRef(collectionName).doc();

  await ref.set({
    ...data,
    'id': ref.id,
  });

  return ref.id;
}


---

## Cubit Responsibility

Cubit should rely on model ids directly:

dart
model.id


NOT firestore document references.

---

## Design Goal

This ensures:

- consistent model structure
- reusable serialization
- predictable local state
- cleaner Cubits
- easier cache synchronization