# GoPark iOS: 3-Week Revised Integration Sprint Plan (Image-Based)

**Target:** Feature-complete integration by **Sunday, December 1st**.
**Objective:** Use detailed, CLI-ready prompts to guide development for a rapid, successful integration based on static images and (X,Y) polygon data.

---

## **Week 1 Sprint (Nov 11 – Nov 17): Setup, Auth & Static Lot Views**
**Goal:** A user can log in/register, see a list of parking lots, and tap one to see the static image with its polygon layout drawn on top.

---

### **Daniel (Data & API Lead)**

**Task 1: Create the Network Singleton (Revised)**
* **File to Create:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Create `NetworkManager.swift`.
    > 1.  Create a `final class NetworkManager` with a `static let shared = NetworkManager()`.
    > 2.  Add a `private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!`.
    > 3.  Create an `async func getHealthz() async throws -> HealthStatus`. It should use `URLSession.shared.data(for:)` to call the `/healthz` endpoint, decode a `HealthStatus` struct, and return it.
    > 4.  **Note: This manager will NOT load the layout JSON. That will be done locally by the view.**"

**Task 2: Define All Data Models (Revised)**
* **File to Create:** `DataModels.swift`
* **CLI Prompt:**
    > "Create `DataModels.swift`. This file will define all `Codable` and `Identifiable` structs for the app.
    > 1.  `struct HealthStatus: Codable { let db: String, let model: String }`
    > 2.  `struct StallFeatures: Codable { let isEV: Bool, let isADA: Bool, let size: String }`
    > 3.  `struct Stall: Codable, Identifiable { let id: String, let features: StallFeatures, let coordinates: [[Double]] }`
    > 4.  `struct StallStatus: Codable, Identifiable { let id: String, let status: String }` (e.g., "FREE" or "TAKEN")
    > 5.  `struct Recommendation: Codable, Identifiable { let id: String, let rank: Int, let reason: String }`
    > 6.  `struct StructuredRequest: Codable { let vehicleType: String, let wantsEV: Bool }`
    > 7.  `struct NLPRequest: Codable { let query: String }`
    > 8.  **Add the helper structs for decoding our local GeoJSON files:** `struct FeatureCollection: Decodable`, `struct Feature: Decodable`, `struct Geometry: Decodable`, and the `struct AnyCodable: Codable` with its custom `init(from:)` and `encode(to:)` methods."

---

### **Jerry (Vision & Map Lead) \[Updated Tasks]**

**Note:** Your tasks have changed. We are no longer using `MapKit` for a GPS map. You will now build the view that shows a **static image** and draw the **(X,Y) pixel polygons** on top of it.

### **Jerry (Vision & Map Lead) \[Updated Tasks]**

**Note:** Your tasks have changed. We are no longer using `MapKit` for a GPS map. You will now build the view that shows a **static image** and draw the **(X,Y) pixel polygons** on top of it.

**Task 1: Create the Static Lot View**
* **File to Create:** `ParkingLotView.swift`
* **CLI Prompt:**
    > "Create `ParkingLotView.swift`.
    > 1.  Add `let lotName: String`, `@State private var stalls: [Stall] = []`, and `@State private var imageSize: CGSize = .zero`.
    > 2.  Add the `private let originalImageSizes: [String: CGSize]` dictionary. Populate it with the **real dimensions** for `lot_a`, `lot_b`, `lot_c`, `lot_d`, and `lot_e`.
    > 3.  The `body` must be a `ZStack`. The bottom layer is `Image(lotName).resizable().aspectRatio(contentMode: .fit)`. Add the `GeometryReader` background modifier to get the `imageSize`.
    > 4.  The top layer of the `ZStack` must be `StallsOverlayView(stalls: stalls, imageSize: imageSize, originalImageSize: originalImageSizes[lotName] ?? .zero)`.
    > 5.  Add an `.onAppear` modifier to the `ZStack` that calls `Task { self.stalls = try await loadLotData(from: "\(lotName)_data.geojson") }`.
    > 6.  Create the `private struct StallsOverlayView: View`. It must have `stalls`, `imageSize`, `originalImageSize`, and a `body` with a `ForEach` loop.
    > 7.  Inside `StallsOverlayView`, create the `private func stallPath(for stall: Stall) -> Path`. This function must contain the **correct scaling logic** (calculating `scale`, `offsetX`, `offsetY`) to draw the polygons.
    > 8.  Create the `private func loadLotData(from filename: String) async throws -> [Stall]` function. This function will load and decode the local GeoJSON file.
    > 9.  At the bottom of the file, add all the necessary helper structs for decoding: `FeatureCollection`, `Feature`, `Geometry` (with `[[[Double]]]`), and the `AnyCodable` struct that correctly handles `null` values."

**Task 2: \[NEW HACKATHON TASK] Deploy Vision Model to Raindrop/Vultr**
* **Goal:** Get your YOLO vision model running on the required hackathon platform.
* **CLI Prompt:**
    > "This is a backend task. Use the **Gemini CLI** to:
    > 1.  Verify that Raindrop's **SmartInference** component can host a custom YOLO model. (This is the project's biggest risk).
    > 2.  If it can't, use Gemini CLI to find a supported vision model on SmartInference that can perform object detection.
    > 3.  Use the **Gemini CLI** to write the necessary configuration and Python code to deploy your chosen vision model to a **SmartInference** endpoint.
    > 4.  This deployment will run on **Vultr's GPU infrastructure**, fulfilling the Vultr service requirement.
    > 5.  Connect this SmartInference endpoint to the main `/predict/stalls` API that will be built on Raindrop's serverless compute."

---

### **Franco (UX/Flow Lead)**

**Task 1: Implement Authentication Logic**
* **File to Create:** `AuthManager.swift`
* **CLI Prompt:**
    > "Create an `AuthManager.swift` file. The file should import `Firebase` and `FirebaseAuth`. Create a `final class AuthManager: ObservableObject`.
    > 1.  It must have a `@Published var userSession: User?`.
    > 2.  It needs a `static let shared = AuthManager()`.
    > 3.  The `init()` should set `userSession = Auth.auth().currentUser`.
    > 4.  Create an `async func signIn(email: String, password: String) throws`.
    > 5.  Create an `async func signUp(email: String, password: String, fullName: String) throws`.
    > 6.  Create a `func signOut()`."

**Task 2: Implement Main App State (The New Flow)**
* **File to Modify:** `ContentView.swift`
* **CLI Prompt:**
    > "Modify `ContentView.swift`.
    > 1.  Add `@StateObject private var authManager = AuthManager.shared`.
    > 2.  The `body` must contain a `Group` that checks `if authManager.userSession == nil`.
    > 3.  If `true`, show `LoginView()`.
    > 4.  If `false` (i.e., user is logged in), show **`LotSelectionView()`**.
    > 5.  Pass the `authManager` as an `EnvironmentObject` to both `LoginView()` and `LotSelectionView()`."

**Task 3: Make Login/Registration Functional**
* **File to Modify:** `LoginView.swift` and `RegistrationView.swift`
* **CLI Prompt:**
    > "Modify `LoginView.swift` and `RegistrationView.swift` to use the `AuthManager`.
    > 1.  Add `@EnvironmentObject var authManager: AuthManager` to both views.
    > 2.  Add `@State` variables for `email`, `password`, etc.
    > 3.  Wire the 'Login' and 'Sign Up' buttons to call the respective `async` functions from the `authManager` within a `Task` block. Include error handling with a `.alert`."

**Task 4: Create the New Main Screen**
* **File to Create:** `LotSelectionView.swift`
* **CLI Prompt:**
    > "Create `LotSelectionView.swift`.
    > 1.  The `body` must be wrapped in a `NavigationView`.
    > 2.  Inside, create a `List` containing `NavigationLink`s.
    > 3.  Create links for each lot: `NavigationLink("Lot A", destination: ParkingLotView(lotName: "lot_a"))`, `NavigationLink("Lot B", destination: ParkingLotView(lotName: "lot_b"))`, and so on for all 5 lots.
    > 4.  Apply `.listStyle(.insetGrouped)` to the `List` to get the gray background.
    > 5.  Set the `.navigationTitle("Select a Lot")`."

---

## **Week 2 Sprint (Nov 18 – Nov 24): "Live" Vision & User Profile**
**Goal:** The (image) map becomes "live" with real-time occupancy, and the app is "personal" (user can save their car info).

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

### **Jerry (Vision & Map Lead)**

**Task 1: Add Live Status API Call**
* **File to Modify:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Modify `NetworkManager.swift`.
    > 1.  Add a new function: `async func getLiveStallStatus(lotName: String) async throws -> [StallStatus]`.
    > 2.  This function should make a `POST` request to `/predict/stalls`. **It should send the `lotName` in the request body** so the backend knows which lot to process.
    > 3.  It should decode an array of `[StallStatus]` and return it."

**Task 2: Make Map Dynamic with Live Data**
* **File to Modify:** `ParkingLotView.swift`
* **CLI Prompt:**
    > "Modify `ParkingLotView.swift`.
    > 1.  Add a new state variable: `@State private var stallStatuses: [String: String] = [:]`. This dictionary will map a `stall.id` to its status (e.g., "FREE").
    > 2.  Add a `Timer` to the `ParkingLotView`: `let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()`.
    > 3.  Add an `.onReceive(timer)` modifier to the `ZStack`. The action should call `Task { await fetchLiveStatus() }`.
    > 4.  Create a `private func fetchLiveStatus() async`. This function must call `NetworkManager.shared.getLiveStallStatus(lotName: self.lotName)` and populate the `stallStatuses` dictionary.
    > 5.  Pass the `stallStatuses` dictionary into `StallsOverlayView`: `StallsOverlayView(stalls: stalls, ..., stallStatuses: stallStatuses)`.
    > 6.  Modify `StallsOverlayView` to accept the new variable: `let stallStatuses: [String: String]`.
    > 7.  Inside `StallsOverlayView`, create a helper `private func colorFor(stall: Stall) -> Color` that checks `stallStatuses[stall.id]` and returns `.green` (for "FREE"), `.red` (for "TAKEN"), or `.gray` (default).
    > 8.  In the `ForEach` loop, update the `stallPath` fill modifier to: `.fill(colorFor(stall: stall).opacity(0.5))`."

---

### **Franco (UX/Flow Lead)**

**Task 1: Make Side Menu Functional**
* **File to Modify:** `SideMenuView.swift` and `LotSelectionView.swift`
* **CLI Prompt:**
    > "First, modify `SideMenuView.swift`.
    > 1.  Add `@EnvironmentObject var authManager: AuthManager`.
    > 2.  Display the user's email: `authManager.userSession?.email`.
    > 3.  Make 'My Profile' a `NavigationLink(destination: ProfileView())`.
    > 4.  Make 'Log Out' call `authManager.signOut()`.
    >
    > Second, modify `LotSelectionView.swift`.
    > 1.  Add `@State private var showSideMenu = false`.
    > 2.  Add a `navigationBarItems(leading: Button(action: { showSideMenu.toggle() }) { Image(systemName: "list.bullet") })`.
    > 3.  Add the `.overlay` logic to the `NavigationView` to show the `SideMenuView` when `showSideMenu` is true."

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
    > 1.  Add `async func getStructuredRecommendation(lotName: String, vehicleType: String, wantsEV: Bool) async throws -> [Recommendation]`.
    > 2.  It must create a `StructuredRequest` body and `POST` it to `/recommend`. **It must include the `lotName`** in the request.
    > 3.  Decode and return the `[Recommendation]` array."

**Task 2: Create Recommendation View Model**
* **File to Create:** `RecommendationViewModel.swift`
* **CLI Prompt:**
    > "Create `RecommendationViewModel.swift`.
    > 1.  Make it a `class RecommendationViewModel: ObservableObject`.
    > 2.  Add `@Published var recommendedStallID: String?`.
    > 3.  Add `@Published var isLoading: Bool = false` and `@Published var errorMessage: String?`.
    > 4.  Create `func getAutoRecommendation(lotName: String) async`.
    > 5.  Inside, set `isLoading = true`, load car info from `UserDefaults`, call `NetworkManager.shared.getStructuredRecommendation(...)`, and set `recommendedStallID` on success or `errorMessage` on failure."

---

### **Franco (UX/Flow Lead)**

**Task 1: Implement NLP Recommend API**
* **File to Modify:** `NetworkManager.swift`
* **CLI Prompt:**
    > "Modify `NetworkManager.swift`.
    > 1.  Add `async func getNLPRecommendation(lotName: String, query: String) async throws -> [Recommendation]`.
    > 2.  It must create an `NLPRequest` body and `POST` it to `/recommend/nl`. **It must include the `lotName`** in the request.
    > 3.  Decode and return the `[Recommendation]` array."

**Task 2: Wire up the AI Chatbot**
* **File to Modify:** `AIChatView.swift`
* **CLI Prompt:**
    > "Modify `AIChatView.swift`.
    > 1.  Add `let lotName: String` and `@Binding var recommendedStallID: String?`.
    > 2.  Add `@State private var messageText: String = ""` and `@State private var messages: [ChatMessage] = []`. (You'll need to define the `ChatMessage` struct).
    > 3.  The 'Send' button action should: add user's message, clear text, then `Task` to call `NetworkManager.shared.getNLPRecommendation(lotName: self.lotName, query: userMessage)`.
    > 4.  On success, add the AI's `reason` as a new message and set `recommendedStallID = response.first?.id`."

**Task 3: Add Error and Loading Polish**
* **File to Modify:** `ParkingLotView.swift`
* **CLI Prompt:**
    > "Modify `ParkingLotView.swift`.
    > 1.  Add `@StateObject private var recVM = RecommendationViewModel()`.
    > 2.  Overlay a `ProgressView("Finding spot...")` on the `ZStack` that is visible `if recVM.isLoading`.
    > 3.  Add an `.alert` modifier triggered by `recVM.errorMessage` to show errors.
    > 4.  Add a 'Chat' button (e.g., in the `navigationBar`) that presents `AIChatView` as a sheet, passing it `lotName` and `$recVM.recommendedStallID`."

---

### **Jerry (Vision & Map Lead)**

**Task 1: Highlight Recommended Spot**
* **File to Modify:** `ParkingLotView.swift`
* **CLI Prompt:**
    > "Modify `ParkingLotView.swift`.
    > 1.  Get the `recVM` via `@StateObject` (as added by Franco's task).
    > 2.  Pass the `recVM.recommendedStallID` into `StallsOverlayView`: `StallsOverlayView(stalls: stalls, ..., recommendedStallID: recVM.recommendedStallID)`.
    > 3.  Modify `StallsOverlayView` to accept the new variable: `let recommendedStallID: String?`.
    > 4.  Inside `StallsOverlayView`'s `ForEach`, add logic to determine the stroke style:
    >     `let isRecommended = stall.id == recommendedStallID`
    >     `let strokeColor = isRecommended ? Color.yellow : Color.gray`
    >     `let lineWidth = isRecommended ? 5.0 : 1.0`
    > 5.  In the `ForEach`, update the `stallPath` stroke modifier to: `.stroke(strokeColor, lineWidth: lineWidth)`."

**Task 2: Final Demo Prep (Revised Flow)**
* **File to Modify:** N/A (Action)
* **CLI Prompt:**
    > "This is a human task. On Sunday, Dec 1st, use QuickTime Player to record a full 2-3 minute screen capture of the iOS Simulator.
    > 1.  Start on the `LoginView` and log in.
    > 2.  Show the new `LotSelectionView`. Tap on "Lot D".
    > 3.  Show the `ParkingLotView` loading and displaying the static image and its red/green spots changing (from the Timer).
    > 4.  Navigate to `ProfileView` and set car type to 'SUV'.
    > 5.  Go back to the `ParkingLotView` for "Lot D". Open the `AIChatView`.
    > 6.  Ask, 'I need a spot for an SUV near the front.'
    > 7.  Close the chat and show the `ParkingLotView` with the new yellow highlighted spot.
    > 8.  Save this video as `GoPark_Demo_V1.mov`."