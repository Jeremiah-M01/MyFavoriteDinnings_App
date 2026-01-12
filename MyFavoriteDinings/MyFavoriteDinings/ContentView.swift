//
//  ContentView.swift
//  MyFavoriteDinings
//
//  Created by Jeremiah Martinez on 11/25/25.
//

import SwiftUI
import SwiftData
import MapKit
import PhotosUI
import CoreLocation

struct ContentView: View {
    @State private var isAuthed: Bool = false
    @State private var currentAccount: Accounts? = nil
    @Environment(\.modelContext) private var context
    @State private var isShowingLaunch: Bool = true
    

    var body: some View {
        ZStack {
            if isAuthed, let account = currentAccount {
                WelcomeView(isAuthed: $isAuthed, account: account)
            }
            else {
                LoginView(isAuthed: $isAuthed, currentAccount: $currentAccount)
            }
            
            //Lauch screen
            if isShowingLaunch {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        self.isShowingLaunch = false
                    }
            }
        }
    }

}

// LaunchScreen page
struct LaunchScreenView: View {
    var body: some View {
        Color.red
            .edgesIgnoringSafeArea(.all)
        
        VStack {
            Text("MyFavoriteDinings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            //Spacer()
            
            Text("Copyright to Jeremiah Martinez")
                .font(.caption)
                .foregroundColor(.white)
                .padding()
        }
    }
}

// Main page
struct WelcomeView: View {
    @Binding var isAuthed: Bool
    @Bindable var account: Accounts
    @State var showAddRestaurantView: Bool = false
    @State var showMapView: Bool = false
    @State var showCommunity: Bool = false
    
    
    var body: some View {
        
        Group {
            if showAddRestaurantView {
                AddRestaurant(account: account, showAddRestaurantView: $showAddRestaurantView)
                
            } else if showMapView {
                
                mapViewUserLoc(showMap: $showMapView, restaurants: account.restaurants)
                
            } else {
                // Add Dynamic Table to store the websites
                NavigationStack {
                    List {
                        ForEach(account.restaurants) { restaurant in
                            NavigationLink {
                                restaurantInfo(account: account, restaurant: restaurant)
                            } label: {
                                Text(restaurant.name)
                                    .font(.headline)
                            }
                        }
                        .onDelete(perform: deleteRestaurant)
                    }
                    .navigationTitle("My Dining List")
                    .toolbar {
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showAddRestaurantView = true
                            } label: {
                                Label("Add", systemImage: "plus")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        
                        // Don't put screen switch logic in toolbar
                        
                    }
                    
                    // Move buttons Here
                    Button("View Map of all Restaurants") {
                        // Change to take to map of all restaurants
                        showMapView = true
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    .foregroundStyle(.red)
                    
                    HStack {
                        Button("Community Page") {
                            // Change to take to community view
                            showCommunity = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.trailing, 40)
                        .tint(.red)
                        
                        
                        Button("Sign out") {
                            isAuthed = false
                        }
                        .foregroundStyle(.black)
                    }
                    .padding(.bottom, 30)
                    
                }
            }
        }
        .fullScreenCover(isPresented: $showCommunity) {
            CommunityView(showCommunity: $showCommunity)
        }
        
    }
    
    private func deleteRestaurant(at offsets: IndexSet) {
        account.restaurants.remove(atOffsets: offsets)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        location = locations.first
    }
    
}


// Map view finish
struct mapViewUserLoc: View {
    @StateObject var locationManager = LocationManager()
    @Binding var showMap: Bool
    
    // variable for coordinates of restaurant if passed in
    var restaurantCoordinate: CLLocationCoordinate2D? = nil
    
    // variable for all restaurants to add pins
    var restaurants: [Restaurant] = []
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            Map(position: $mapPosition) {
                ForEach(restaurants) { restaurant in
                    Annotation(
                        restaurant.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: restaurant.latitude,
                            longitude: restaurant.longitude
                        )
                    ) {
                        ZStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 25, height: 25)
                        }
                    }
                }
            }
            .onAppear {
                
                if let targetCoordinate = restaurantCoordinate {
                    // Center on restaurant
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: targetCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                    return
                }
                
                if !restaurants.isEmpty {
                    let coords = restaurants.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    }
                    
                    let minLat = coords.map { $0.latitude }.min()!
                    let maxLat = coords.map { $0.latitude }.max()!
                    let minLon = coords.map { $0.longitude }.min()!
                    let maxLon = coords.map { $0.longitude }.max()!
                    
                    let center = CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    )
                    
                    let span = MKCoordinateSpan(
                        latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
                        longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
                    )
                    
                    mapPosition = .region(MKCoordinateRegion(center: center, span: span))
                    return
                    
                }
                
                if let loc = locationManager.location {
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                    
                }
            }
            .ignoresSafeArea()
            
            Button {
                showMap = false
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.largeTitle)
                    .padding()
            }
        }
        
    }
}


// Restaurant info view
struct restaurantInfo: View {
    @Bindable var account: Accounts
    var restaurant: Restaurant
    @State private var showButton = true
    @State private var showMap = false
    @State private var showPhotos: Bool = false
    
    var body: some View {
        
        ZStack {
            // Change Background Color
            Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center) {
                Text(restaurant.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 35)
                
                // Photos Will go here
                if let firstData = restaurant.photos.first,
                   let uiImage = UIImage(data: firstData) {
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit( )
                        .frame(height: 250)
                        .cornerRadius(12)
                    
                }
                
                Button {
                    // Change to take to photo gallery of all photos
                    showPhotos = true
                    
                } label: {
                    Label("View all Photos", systemImage: "photo.on.rectangle.fill")
                }
                .padding()
                .foregroundStyle(.red)
                
                Text("Notes: \n\(restaurant.notes ?? "")")
                    .font(.headline)
                    .padding(.leading, 0)
                    .padding(.bottom, 62)
                    .cornerRadius(10)
                
                // Buttons for Viewing on map and buttons to make public
                Button("View on Map") {
                    // Change to take to map of all restaurants centered on the restaurant
                    showMap = true
                }
                .buttonStyle(.bordered)
                .padding()
                .foregroundStyle(.red)
                
                if !restaurant.isPublic {
                    Button("Make Notes Public") {
                        // Change to make the notes on this resturant public
                        restaurant.isPublic = true
                        
                        //showButton = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.trailing, 40)
                    .tint(.red)
                } else {
                    
                    Button("Make Notes Private") {
                        // Change to make the notes on this resturant private
                        restaurant.isPublic = false
                        
                        //showButton = true
                    }
                    .buttonStyle(.bordered)
                    .padding(.trailing, 40)
                    .tint(.red)
                }
                
            }
            .fullScreenCover(isPresented: $showMap) {
                mapViewUserLoc(
                    showMap: $showMap,
                    restaurantCoordinate: CLLocationCoordinate2D(
                        latitude: restaurant.latitude,
                        longitude: restaurant.longitude
                    ),
                    restaurants: account.restaurants
                )
            }
            .fullScreenCover(isPresented: $showPhotos) {
                PhotoGalleryView(photos: restaurant.photos)
            }
            
        }
        
    }
}



// AddRestaurant view (to be Restaurant)
struct AddRestaurant: View {
    @Environment(\.modelContext) private var context
    @Bindable var account: Accounts
    @Binding var showAddRestaurantView: Bool
    
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    
    var body: some View {

        // Code for entering website info simillar to sign in
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    // Had to split up into subviews for compiler
                    restaurantFieldsSection
                    photoPickerSection
                    statusSection
            
                } // end of form
                .scrollContentBackground(.hidden)
                .background(Color.red.opacity(0.2))
                
                if !loadedImages.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(loadedImages, id: \.self) { img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                    }
                }
    
            }
            .navigationTitle("Add Restaurant")
            .toolbar {
                toolbarContent
            }
            .onChange(of: selectedPhotos) {
                loadSelectedPhotos()
            }
        } // end of navStack
        
    }
    
    // sections for form
    private var restaurantFieldsSection: some View {
        Section("Add Restaurant Details") {
            
            TextField("Restaurant Name", text: $name)
            
            TextField("Address", text: $address)
            
            TextField("Notes", text: $notes)
                .lineLimit(3...6)
            
        }
    }
    
    private var photoPickerSection: some View {
        Section("Photos") {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Add Photos", systemImage: "photo.on.rectangle.fill")
            }
            .foregroundStyle(.red)
        }
    }
    
    private var statusSection: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Finding Address...")
                    Spacer()
                }
            }
            
            // error message
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Cancel"){
                showAddRestaurantView = false
            }
            Button("Save", action: saveRestaurant)
                .disabled(name.isEmpty || address.isEmpty)
        }
        
    }
    
    // load photos
    private func loadSelectedPhotos() {
        loadedImages.removeAll()
        
        Task {
            loadedImages.removeAll()
            
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data){
                    loadedImages.append(uiImage)
                    
                }
            }
        }
    }
    
    func saveRestaurant() {
        isLoading = true
        errorMessage = nil
        
        geocodeAddress(address) { coordinate in
            DispatchQueue.main.async {
                isLoading = false
                
                
                guard let coordinate = coordinate else {
                    self.errorMessage = "Could not geocode address"
                    return
                }
                
                // Convert photo UIImages into jpeg data
                let photoData = loadedImages.compactMap {
                    $0.jpegData(compressionQuality: 0.8)
                }
                
                // Build the resturant obj
                let newRestaurant = Restaurant(
                    name: name,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    notes: notes,
                    photos: photoData
                )
                
                // Save
                account.restaurants.append(newRestaurant)
                showAddRestaurantView = false
            }
        }
    }
    
    func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            completion(placemark.location?.coordinate)
        }
    }
    
}

struct PhotoGalleryView: View {
    let photos: [Data]
    @Environment(\.dismiss) private var dismiss
    
    private let gridItems = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 12) {
                    ForEach(photos, id: \.self) { photo in
                        if let uiImage = UIImage(data: photo) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 122)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        } else {
                            Color.gray
                                .frame(height: 122)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                    }
                }
                .padding()
            }
            .navigationTitle(Text("Photo Gallery"))
            .toolbar {
                Button("Close") {
                    dismiss()
                }
            }
            
        }
        
    }
}

struct CommunityView: View {
    @Environment(\.modelContext) private var context
    @Binding var showCommunity: Bool
    
    private let gridItems = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 20) {
                    ForEach(fetchPublicRestaurants(), id: \.restaurant.id) { item in
                        CommunityCardView(restaurant: item.restaurant, user: item.user)
                    }
                }
                .padding()
                
            }
            .navigationTitle(Text("Community Page"))
            .toolbar {
                Button("Close") {
                    showCommunity = false
                }
            }
        }
        
    }
    
    private func fetchPublicRestaurants() -> [(restaurant: Restaurant, user: Accounts)] {
        let accounts = (try? context.fetch(FetchDescriptor<Accounts>())) ?? []
        
        var results: [(restaurant: Restaurant, user: Accounts)] = []
        
        for account in accounts {
            for restaurant in account.restaurants where restaurant.isPublic {
                results.append((restaurant, account))
            }
        }
        
        return results
        
    }
}

struct CommunityCardView: View {
    let restaurant: Restaurant
    let user: Accounts
    @State private var address: String = "Loading..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            if let data = restaurant.photos.first,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(10)
            } else {
                ZStack {
                    Color.gray
                    Image(systemName: "photo")
                        .foregroundStyle(.white)
                }
                .frame(height: 150)
                .cornerRadius(10)
            }
            Text(restaurant.name)
                .font(.headline)
                .lineLimit(3)
            
            Text(restaurant.notes ?? "(no notes)")
                .font(.body)
                .lineLimit(3)
            
            Text("Location: \(address)")
                .font(.callout)
            
            Text("- \(user.username)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onAppear {
            convertCoordinatesToAddress()
        }
    }
    
    func convertCoordinatesToAddress() {
        let location = CLLocation(
            latitude: restaurant.latitude,
            longitude: restaurant.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let place = placemarks?.first {
                address = "\(place.locality ?? ""), \(place.administrativeArea ?? "")"
            }
        }
    }
}


// LogIn view
struct LoginView: View {
    @Environment(\.modelContext) private var context
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var info = ""
    @State private var showPassword: Bool = false
    
    @Binding var isAuthed: Bool
    @Binding var currentAccount: Accounts?
    
    var body: some View {
        
        VStack {
            Text("Log In")
                .font(.largeTitle)
                .padding()
                .bold()
            
            TextField("Username", text: $username)
                .padding()
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            
            HStack {
                if showPassword {
                    TextField("Password", text: $password)
                        .padding()
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Password", text: $password)
                        .padding()
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                }
                
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 15)
            }
            
            Button {
                password = generatePassword()
            } label: {
                Label("Generate Password", systemImage: "arrow.clockwise.circle")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            Text(info)
                .foregroundStyle(.red)
            
            HStack {
                Button("Sign in") {
                    signIn()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Button("Sign up") {
                    signUp()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
            }
            .padding(.top, 50)
        }
        
    }
    
    private func signIn() {
        
        guard !username.isEmpty, !password.isEmpty else {
            info = "Please enter a Username and password."
            return
        }
        
        if let accounts = try?
            context.fetch(FetchDescriptor<Accounts>()) {
            for account in accounts {
                if account.username == username &&
                    account.password == password {
                    currentAccount = account
                    isAuthed = true
                    return
                }
            }
            info = "Invalid username or password."
        }
        else {
            info = "No accounts found."
        }
    }
    
    private func signUp() {
        
        // Anything after guard is like if statement separated by commas
        guard !username.isEmpty, !password.isEmpty else {
            
            info = "Please enter a Username and password."
            return
        }
        
        context.insert(Accounts(username: username, password: password))
        try? context.save()
        info = "Account created successfully!"
        
    }
    
    // Function to generate a random 8 character password
    private func generatePassword() -> String {
        let letters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@$%^&*()_-?")
        var password = ""
        for _ in 0..<8 {
            password.append(letters.randomElement()!)
        }
        return password
    }
    
}


// Other Views if needed

#Preview {
    ContentView()
        //.modelContainer(for: Item.self, inMemory: true)
}
