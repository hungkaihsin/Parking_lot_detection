
import SwiftUI

import MapKit



struct MainMapView: View {

    @State private var searchText = ""

    @State private var showChat = false

    @State private var showSideMenu = false

    @Binding var isLoggedIn: Bool

    @State private var region = MKCoordinateRegion(

        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),

        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)

    )



    var body: some View {

        ZStack {

            Map(coordinateRegion: $region)

                .edgesIgnoringSafeArea(.all)



            VStack {

                HStack {

                    Button(action: {

                        showSideMenu.toggle()

                    }) {

                        Image(systemName: "list.bullet")

                            .font(.title)

                            .padding()

                            .background(Color.white)

                            .cornerRadius(10)

                            .shadow(radius: 5)

                    }

                    .padding(.leading)



                    Spacer()

                }

                .padding(.top, 50)



                Text("GoPark")

                    .font(.largeTitle)

                    .fontWeight(.bold)



                HStack {

                    Image(systemName: "magnifyingglass")

                        .foregroundColor(.gray)

                    TextField("Search for a destination...", text: $searchText)

                }

                .padding()

                .background(Color.white)

                .cornerRadius(10)

                .padding(.horizontal)



                Spacer()

            }



            VStack {

                Spacer()

                HStack {

                    Spacer()

                    VStack {

                        Button(action: {

                            // Current Location Action

                        }) {

                            Image(systemName: "location.fill")

                                .padding()

                                .background(Color.white)

                                .foregroundColor(.blue)

                                .cornerRadius(10)

                                .shadow(radius: 5)

                        }



                        Button(action: {

                            showChat = true

                        }) {

                            Image(systemName: "message.fill")

                                .font(.title)

                                .padding(25)

                                .background(Color.blue)

                                .foregroundColor(.white)

                                .clipShape(Circle())

                                .shadow(radius: 10)

                        }

                        .padding(.top, 10)

                    }

                    .padding()

                }

            }

        }

        .sheet(isPresented: $showChat) {

            AIChatView()

        }

        .overlay(

            Group {

                if showSideMenu {

                    Color.black.opacity(0.4)

                        .edgesIgnoringSafeArea(.all)

                        .onTapGesture {

                            showSideMenu = false

                        }



                    SideMenuView(showMenu: $showSideMenu, isLoggedIn: $isLoggedIn)

                        .transition(.move(edge: .leading))

                }

            }

        )

    }

    

    private func convertCoordinates(_ coords: [[Double]]) -> [CLLocationCoordinate2D] {

        return coords.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }

    }

}



struct MainMapView_Previews: PreviewProvider {

    static var previews: some View {

        MainMapView(isLoggedIn: .constant(true))

    }

}