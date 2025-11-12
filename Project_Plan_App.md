# GoPark iOS: 3-Week Detailed Integration Sprint Plan

**Target:** Feature-complete integration by **Sunday, December 1st**.
**Objective:** Use detailed, CLI-ready prompts to guide development for a rapid, successful integration.

---

## **Week 1 Sprint (Nov 11 – Nov 17): Setup, Auth & Static Map Layer**
**Goal:** A user can log in/register, and the app will render the complete, *static* parking lot layout from the backend.

---

### **Franco (UX/Flow Lead)**

**Task 1: Implement Authentication Logic**
* **File to Create:** `AuthManager.swift`
* **CLI Prompt:**
    > "Create an `AuthManager.swift` file. The file should import `Firebase` and `FirebaseAuth`. Create a `final class AuthManager: ObservableObject`.
    > 1.  It must have a `@Published var userSession: User?`.
    > 2.  It needs a `static let shared = AuthManager()`.
    > 3.  The `init()` should set `userSession = Auth.auth().currentUser`.
    > 4.  Create an `async func signIn(email: String, password: String) throws`. It should call `Auth.auth().signIn(withEmail: email, password: password)` and set `self.userSession` on success.
    > 5.  Create an `async func signUp(email: String, password: String, fullName: String) throws`. It should call `Auth.auth().createUser(withEmail: email, password: password)` and then set the user's `displayName`.
    > 6.  Create a `func signOut()`. It should call `Auth.auth().signOut()` and set `self.userSession = nil`."

**Task 2: Implement Main App State**
* **File to Modify:** `ContentView.swift`
* **CLI Prompt:**
    > "Modify `ContentView.swift`.
    > 1.  Add `@StateObject private var authManager = AuthManager.shared`.
    > 2.  The `body` must contain a `Group` that checks `if authManager.userSession == nil`.
    > 3.  If `true`, show `LoginView()`.
    > 4.  If `false` (i.e., user is logged in), show `MainMapView()`.
    > 5.  This will handle the main app flow for authentication."

**Task 3: Make Login/Registration Functional**
* **File to Modify:** `LoginView.swift` and `RegistrationView.swift`
* **CLI Prompt:**
    > "Modify `LoginView.swift`.
    > 1.  Add `@EnvironmentObject var authManager: AuthManager`.
    > 2.  Add `@State` for `email` and `password`.
    > 3.  The 'Login' button's action should be a `Task` that calls `await authManager.signIn(email: email, password: password)`. Handle errors with a `.alert`.
    >
    > Then, modify `RegistrationView.swift`.
    > 1.  Add `@EnvironmentObject var authManager: AuthManager`.
    > 2.  Add `@State` for `email`, `password`, and `fullName`.
    > 3.  The 'Sign Up' button's action should be a `Task` that calls `await authManager.signUp(email: email, password: password, fullName: fullName)`."

---

### **Daniel (Data & API Lead)**

**Task 1: Create the Network Singleton**
* **File to Create:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Create `NetworkManager.swift`.
    > 1.  Create a `final class NetworkManager` with a `static let shared = NetworkManager()`.
    > 2.  Add a `private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!`.
    > 3.  Create an `async func getHealthz() async throws -> HealthStatus`. It should use `URLSession.shared.data(for:)` to call the `/healthz` endpoint, decode a `HealthStatus` struct, and return it.
    > 4.  Create an `async func getLotLayout(lotId: String) async throws -> [Stall]`. It should call `/lots/{lotId}/spots`, decode an array of `Stall` structs, and return it."

**Task 2: Define All Data Models**
* **File to Create:** `DataModels.swift`
* **CLI Prompt:**
    > "Create `DataModels.swift`. This file will define all `Codable` and `Identifiable` structs for the app.
    > 1.  `struct HealthStatus: Codable { let db: String, let model: String }`
    > 2.  `struct StallFeatures: Codable { let isEV: Bool, let isADA: Bool, let size: String }`
    > 3.  `struct Stall: Codable, Identifiable { let id: String, let features: StallFeatures, let coordinates: [[Double]] }`
    > 4.  `struct StallStatus: Codable, Identifiable { let id: String, let status: String }` (e.g., "FREE" or "TAKEN")
    > 5.  `struct Recommendation: Codable, Identifiable { let id: String, let rank: Int, let reason: String }`
    > 6.  `struct StructuredRequest: Codable { let vehicleType: String, let wantsEV: Bool }`
    > 7.  `struct NLPRequest: Codable { let query: String }`"

---

### **Jerry (Vision & Map Lead)**

**Task 1: Draw Static Map Polygons**
* **File to Modify:** `MainMapView.swift`
* **CLI Prompt:**
    > "Modify `MainMapView.swift`. It must import `MapKit`.
    > 1.  Add `@State private var stalls: [Stall] = []`.
    > 2.  Add `@State private var region = MKCoordinateRegion(...)` centered on the parking lot's coordinates.
    > 3.  The `body` must use a `Map(coordinateRegion: $region)` view.
    > 4.  Inside the `Map`, use a `ForEach(stalls)` loop.
    > 5.  Inside the `ForEach`, create a `MapPolygon(coordinates: convertCoordinates(stall.coordinates))`.
    > 6.  Style the `MapPolygon` with `.fill(Color.gray.opacity(0.4))` and `.stroke(Color.gray, lineWidth: 1)`.
    > 7.  Add a helper function `func convertCoordinates(_ coords: [[Double]]) -> [CLLocationCoordinate2D]` to map the `[[Double]]` array to `[CLLocationCoordinate2D]`.
    > 8.  Add an `.onAppear` modifier to the `Map`. Inside it, create a `Task` to call `self.stalls = await NetworkManager.shared.getLotLayout(lotId: "default")`, handling any errors."

---
---

## **Week 2 Sprint (Nov 18 – Nov 24): "Live" Vision & User Profile**
**Goal:** The map becomes "live" with real-time occupancy, and the app is "personal" (user can save their car info).

---

### **Jerry (Vision & Map Lead)**

**Task 1: Add Live Status API Call**
* **File to Modify:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Modify `NetworkManager.swift`.
    > 1.  Add a new function: `async func getLiveStallStatus() async throws -> [StallStatus]`.
    > 2.  This function should make a `POST` request to `/predict/stalls`.
    > 3.  It should decode an array of `[StallStatus]` and return it."

**Task 2: Make Map Dynamic with Live Data**
* **File to Modify:** `MainMapView.swift`
* **CLI Prompt:**
    > "Modify `MainMapView.swift`.
    > 1.  Add `@State private var stallStatuses: [String: String] = [:]`. This dictionary will map a `stall.id` to its status (e.g., "FREE").
    > 2.  Add a `Timer` to the view: `let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()`.
    > 3.  Add an `.onReceive(timer)` modifier. The action should call `Task { await fetchLiveStatus() }`.
    > 4.  Create a new `private func fetchLiveStatus() async`. This function should call `NetworkManager.shared.getLiveStallStatus()`, loop through the results, and populate the `stallStatuses` dictionary.
    > 5.  Create a helper function `private func colorFor(stall: Stall) -> Color`. It should check `stallStatuses[stall.id]`. `if status == "FREE" { return .green } else if status == "TAKEN" { return .red } else { return .gray }`.
    > 6.  In the `ForEach` loop, update the `MapPolygon`'s fill: `.fill(colorFor(stall: stall).opacity(0.5))`."

---

### **Daniel (Data & API Lead)**

**Task 1: Implement Profile Logic**
* **File to Modify:** `ProfileView.swift`
* **CLI Prompt:**
    > "Modify `ProfileView.swift`.
    > 1.  Add `@State private var vehicleType: String = ""` and other states for `make`, `model`, etc.
    > 2.  In the `body`, create a `Picker` for 'Vehicle Type' with options like 'Compact', 'Sedan', 'SUV', 'EV'. Bind this to `$vehicleType`.
    > 3.  The 'Save Car Details' button action should save the selected values to `UserDefaults.standard`. Example: `UserDefaults.standard.set(vehicleType, forKey: "userVehicleType")`.
    > 4.  Add an `.onAppear` modifier to the view. Inside, load the saved values from `UserDefaults` to populate the `@State` variables, so the form always shows the saved selection."

---

### **Franco (UX/Flow Lead)**

**Task 1: Make Side Menu Functional**
* **File to Modify:** `SideMenuView.swift` and `MainMapView.swift`
* **CLI Prompt:**
    > "Modify `SideMenuView.swift`.
    > 1.  Add `@EnvironmentObject var authManager: AuthManager`.
    > 2.  In the header, display `authManager.userSession?.email ?? "User"`.
    > 3.  The 'My Profile' item should be a `NavigationLink(destination: ProfileView())`.
    > 4.  The 'Log Out' button's action should call `authManager.signOut()`.
    >
    > Then, modify `MainMapView.swift`.
    > 1.  Wrap the entire `body` in a `NavigationView`.
    > 2.  Add the logic to present the `SideMenuView` (e.g., as a slide-over sheet or with a custom `ZStack` overlay) when a 'Menu' button in the navigation bar is tapped."

---
---

## **Week 3 Sprint (Nov 25 – Dec 1): AI Recommender & Final Demo Prep**
**Goal:** The app is now "smart." Integrate all AI endpoints, handle errors, and produce the final demo video.

---

### **Daniel (Data & API Lead)**

**Task 1: Implement Structured Recommend API**
* **File to Modify:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Modify `NetworkManager.swift`.
    > 1.  Add a new function: `async func getStructuredRecommendation(vehicleType: String, wantsEV: Bool) async throws -> [Recommendation]`.
    > 2.  Inside, create a `StructuredRequest` body object with the parameters.
    > 3.  Encode this object as JSON data.
    > 4.  Make a `POST` request to `/recommend` with the JSON data.
    > 5.  Decode and return the `[Recommendation]` array."

**Task 2: Create Recommendation View Model**
* **File to Create:** `RecommendationViewModel.swift`
* **CLI Prompt:**
    > "Create `RecommendationViewModel.swift`.
    > 1.  Make it a `class RecommendationViewModel: ObservableObject`.
    > 2.  Add `@Published var recommendedStallID: String?`.
    > 3.  Add `@Published var isLoading: Bool = false`.
    > 4.  Add `@Published var errorMessage: String?`.
    > 5.  Create a function `func getAutoRecommendation() async`.
    > 6.  Inside, set `isLoading = true`. Load the user's car info from `UserDefaults`.
    > 7.  Call `NetworkManager.shared.getStructuredRecommendation(...)`.
    > 8.  On success, set `self.recommendedStallID` to the `id` of the first recommendation.
    > 9.  Use a `catch` block to set `self.errorMessage`.
    > 10. In a `finally` block, set `isLoading = false`."

---

### **Franco (UX/Flow Lead)**

**Task 1: Implement NLP Recommend API**
* **File to Modify:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Modify `NetworkManager.swift`.
    > 1.  Add a new function: `async func getNLPRecommendation(query: String) async throws -> [Recommendation]`.
    > 2.  Create an `NLPRequest(query: query)` body object.
    > 3.  Encode it, make a `POST` request to `/recommend/nl`, decode, and return the `[Recommendation]` array."

**Task 2: Wire up the AI Chatbot**
* **File to Modify:** `AIChatView.swift`
* **CLI Prompt:**
    > "Modify `AIChatView.swift`.
    > 1.  It needs a `Binding<String?>` to the `recommendedStallID` from the `RecommendationViewModel`.
    > 2.  Add `@State private var messageText: String = ""` and `@State private var messages: [ChatMessage] = []`.
    > 3.  The `body` needs a `ScrollViewReader` and a `ScrollView` to display the chat messages.
    > 4.  The 'Send' button action should:
        * Add the user's message to the `messages` array.
        * Clear `messageText`.
        * Create a `Task` to call `NetworkManager.shared.getNLPRecommendation(query: userMessage)`.
        * On success, add the AI's `reason` as a new `ChatMessage`.
        * Crucially, set `recommendedStallID = response.first?.id` to update the binding."

**Task 3: Add Error and Loading Polish**
* **File to Modify:** `MainMapView.swift`
* **CLI Prompt:**
    > "Modify `MainMapView.swift`.
    > 1.  Add `@StateObject private var recVM = RecommendationViewModel()`.
    > 2.  Overlay a `ProgressView("Finding spot...")` on the map that is visible `if recVM.isLoading`.
    > 3.  Add an `.alert` modifier that is triggered `when: $recVM.errorMessage`. It should display the error message and an 'OK' button to dismiss.
    > 4.  Pass `recVM` as an `EnvironmentObject` or pass the `Binding<String?>` for `recommendedStallID` into the `AIChatView`."

---

### **Jerry (Vision & Map Lead)**

**Task 1: Highlight Recommended Spot**
* **File to Modify:** `MainMapView.swift`
* **CLI Prompt:**
    > "Modify `MainMapView.swift`.
    > 1.  It must get the `recommendedStallID` from the `RecommendationViewModel` (e.g., `@EnvironmentObject var recVM: RecommendationViewModel`).
    > 2.  Create a helper function `private func strokeColorFor(stall: Stall) -> Color`. It should `if stall.id == recVM.recommendedStallID { return .yellow } else { return .gray }`.
    > 3.  Create a helper function `private func lineWidthFor(stall: Stall) -> CGFloat`. It should `if stall.id == recVM.recommendedStallID { return 5.0 } else { return 1.0 }`.
    > 4.  In the `ForEach` loop, update the `MapPolygon` modifiers:
        * `.stroke(strokeColorFor(stall: stall), lineWidth: lineWidthFor(stall: stall))`
        * `.fill(colorFor(stall: stall).opacity(0.5))`"

**Task 2: Final Demo Prep**
* **File to Modify:** N/A (Action)
* **CLI Prompt:**
    > "This is a human task. On Sunday, Dec 1st, use QuickTime Player to record a full 2-3 minute screen capture of the iOS Simulator.
    > 1.  Start on the `LoginView`.
    > 2.  Log in.
    > 3.  Go to `ProfileView` and set your car type.
    > 4.  Go back to the map. Show the red/green spots changing.
    > 5.  Go to the `AIChatView` and ask for a spot.
    > 6.  Go back to the map and show the new yellow highlighted spot.
    > 7.  Save this video as `GoPark_Demo_V1.mov`."