//
//  ContentView.swift
//  FundTransferApp
//
//  Created by Chirag's on 22/09/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var dragDrop = UserDragDrop()
    @Namespace private var viewSpace
    var body: some View {
        ZStack {
            VStack {
                TopBarView()
                Spacer()
                CardView().padding(.top, 30)
                RecentlyTradeView(dragDrop: dragDrop, viewSpace: viewSpace).padding(.top, 20)
            }.padding(.horizontal).padding(.top, 80)
            if dragDrop.dragDropConfig.isDroppedOnPayment {
                PaymentView(viewSpace: viewSpace, dragDrop: dragDrop)
            }
            
            if dragDrop.dragDropConfig.isDroppedOnCollect {
                
            }
        }.background(Color.background).edgesIgnoringSafeArea(.all)
    }
}

struct TopBarView: View {
    var body: some View {
        HStack(spacing: 20){
            Circle().frame(width: 50, height: 50)
            Spacer()
            ZStack {
                Circle().fill(Color.white).frame(width: 50, height: 50)
                Image(systemName: "bell")
            }
            ZStack {
                Circle().fill(Color.white).frame(width: 50, height: 50)
                Image(systemName: "ellipsis").rotationEffect(.degrees(90))
            }
        }
    }
}

struct CardView: View {
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 25.0).fill(Color.cardLinear).frame(height: 220)
            VStack(alignment:.leading, spacing: 15){
                HStack(alignment: .top) {
                    Text("Hello, Dimest \nBalance")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Text("P") .font(.system(size: 30, weight: .heavy)).italic()
                }
                Text("$9444.00")
                    .font(.system(size: 30, weight: .heavy))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15).frame(height: 50)
                    HStack {
                        Text("Your Transaction")
                        Spacer()
                        Image(systemName: "chevron.down")
                    }.padding(.horizontal).foregroundColor(.black)
                }
            }.padding(.horizontal).foregroundColor(.white)
        }
    }
}

struct PaymentView: View {
    public var viewSpace: Namespace.ID
    @ObservedObject var dragDrop:UserDragDrop
    var body: some View {
        ZStack {
            Rectangle().onTapGesture {
                withAnimation {
                    dragDrop.dragDropConfig.isDroppedOnPayment = false
                }
            }
            VStack {
                Spacer(minLength: 100)
                RoundedRectangle(cornerRadius: 25.0).fill(Color.white).matchedGeometryEffect(id: "viewID", in: viewSpace)
            }
        }
    }
}

struct MenuSelectionView: View {
    @ObservedObject var dragDrop:UserDragDrop
    public var viewSpace: Namespace.ID
    var body: some View {
        HStack{
            GeometryReader {geo in
                MenuItemView(imageName: "creditcard.fill", title: "Payment",didEntered: dragDrop.dragDropConfig.isEnteredPayment)
                    .matchedGeometryEffect(id: "viewID", in: viewSpace)
                    .onAppear{
                    self.dragDrop.paymentViewRect = geo.frame(in: .global)
                }
            }
            
            GeometryReader {geo in
                MenuItemView(imageName: "dollarsign.circle", title: "Collect Money",didEntered: dragDrop.dragDropConfig.isEnteredCollect).onAppear{
                    self.dragDrop.collectViewRect = geo.frame(in: .global)
                }
            }
        }.frame(height: 150)
    }
}

struct MenuItemView: View {
    let imageName: String
    let title: String
    var didEntered: Bool = false
    var body: some View {
        ZStack(alignment: .leading){
            RoundedRectangle(cornerRadius: 20).fill(Color.white).overlay(
                RoundedRectangle(cornerRadius: 20).stroke(lineWidth: didEntered ? 2.0 : 0.0)
            )
            VStack(alignment: .leading) {
                ZStack {
                    Circle().fill(Color.logoLinear).frame(width: 45, height: 45)
                    Image(systemName: imageName).foregroundColor(.white)
                }
                Text(title)
            }.padding(.horizontal)
        }
    }
}

struct RecentlyTradeView: View {
    @ObservedObject var userManager = UserManager()
    @State var isRotating = false
    @ObservedObject var dragDrop:UserDragDrop
    public var viewSpace: Namespace.ID
    @State var pickedUserName = "p1"
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack{
                MenuSelectionView(dragDrop: dragDrop, viewSpace: viewSpace).padding(.all, 2)
                RecentlyTitleView().padding(.top, 20)
                ZStack {
                    RotationPathView(isRotating: self.$isRotating)
                    ForEach(userManager.userData) {user in
                        UserView(user: user).rotationEffect(.degrees(isRotating ? 360 : 0)).animation(Animation.linear(duration: 10.0).repeatForever(autoreverses: false)).opacity(userManager.userData[user.id].isDragging ? 0.0 : 1.0).gesture(
                            DragGesture(minimumDistance: 0).onChanged({ (value) in
                                if pickedUserName == "p1" {
                                    pickedUserName = user.imageName
                                    dragDrop.pickedUser = user
                                    dragDrop.shouldScroll = false
                                    dragDrop.dragDropConfig.isDragging = true
                                    userManager.changedUserDraggingValue(index: user.id)
                                }
                                dragDrop.checkRectEnter(location: value.location)
                            }).onEnded({ (value) in
                                userManager.changedUserDraggingValue(index: user.id)
                                dragDrop.checkDrop()
                                pickedUserName = "p1"
                            })
                        )
                    }
                    
                    GeometryReader { geo in
                        UserViewForDrag(user: dragDrop.pickedUser).offset(x: dragDrop.offsetValue.x - 30, y:dragDrop.offsetValue.y - 30).opacity(dragDrop.dragDropConfig.isDragging ? 1.0 : 0.0).onAppear {
                            self.dragDrop.userViewRect = geo.frame(in: .global)
                            self.dragDrop.dragUserMovingPoint = CGPoint(x:  self.dragDrop.userViewRect.minX, y: self.dragDrop.userViewRect.minY)
                        }
                    }.frame(width: 60, height: 60)
                }.padding(.top, 30)
                
            }.onAppear{
                self.isRotating = true
            }
        }
    }
}

class UserDragDrop: ObservableObject {
    var paymentViewRect = CGRect()
    var collectViewRect = CGRect()
    var userViewRect = CGRect()
    @Published var dragDropConfig = DragDropConfig()
    @Published var shouldScroll = true
    
    var scrollAxis: Axis.Set {
        return shouldScroll ? .vertical : []
    }
    
    @Published var pickedUser  = Data.data[0]
    
    @Published var dragUserMovingPoint = CGPoint()
    @Published var offsetValue = CGPoint(x: 0, y: 0)
    
    
    func checkRectEnter(location: CGPoint) {
        offsetValue = location
        dragUserMovingPoint = CGPoint(x: userViewRect.minX + offsetValue.x - 30, y: userViewRect.minY + offsetValue.y - 30)
        let userRect =  CGRect(x: dragUserMovingPoint.x, y: dragUserMovingPoint.y, width: 60, height: 60)
        if paymentViewRect.intersects(userRect) {
            if (dragDropConfig.isEnteredCollect)  {
                dragDropConfig.isEnteredCollect = false
            }
            if !dragDropConfig.isEnteredPayment  {
                dragDropConfig.isEnteredPayment = true
            }
        }else {
            if dragDropConfig.isEnteredPayment  {
                dragDropConfig.isEnteredPayment = false
            }
            if collectViewRect.intersects(userRect) {
                if !dragDropConfig.isEnteredCollect  {
                    dragDropConfig.isEnteredCollect = true
                }
            }else {
                if dragDropConfig.isEnteredCollect  {
                    dragDropConfig.isEnteredCollect = false
                }
            }
        }
        
    }
    
    func checkDrop(){
        shouldScroll = true
        dragDropConfig.isDragging = false
        offsetValue = CGPoint(x: 0, y: 0)
        dragUserMovingPoint = CGPoint(x: userViewRect.minX, y: userViewRect.minY)
        if dragDropConfig.isEnteredPayment {
            dragDropConfig.isEnteredPayment = false
            withAnimation {
                dragDropConfig.isDroppedOnPayment = true
            }
        }
        
        if dragDropConfig.isEnteredCollect {
            dragDropConfig.isEnteredCollect = false
            withAnimation {
                dragDropConfig.isDroppedOnCollect = true
            }
        }
    }
}

struct DragDropConfig {
    var isEnteredPayment = false
    var isEnteredCollect = false
    
    var isDragging = false
    
    var isDroppedOnPayment = false
    var isDroppedOnCollect = false
}

struct RecentlyTitleView: View {
    var body: some View {
        HStack{
            Text("Recently traded").font(.system(size: 20, weight: .bold))
            Spacer()
            Image(systemName: "chevron.right")
        }
    }
}

struct RotationPathView: View {
    @Binding var isRotating: Bool
    var body: some View {
        ZStack{
            Circle().stroke(style: StrokeStyle(lineWidth: 1, lineCap: .square, dash: [8])).frame(width: 300, height: 300).rotationEffect(.degrees(isRotating ? 360 : 0))
            Circle().stroke(style: StrokeStyle(lineWidth: 1, lineCap: .square, dash: [8])).frame(width: 170, height: 170).rotationEffect(.degrees(isRotating ? -360 : 0))
            
            Circle().stroke(style: StrokeStyle(lineWidth: 1, lineCap: .square, dash: [8])).frame(width: 60, height: 60).rotationEffect(.degrees(isRotating ? 360 : 0))
        }.animation(Animation.linear(duration: 10.0).repeatForever(autoreverses: false)).opacity(0.5)
    }
}

struct UserView: View {
    let user: User
    var body: some View {
        ZStack{
            Circle().fill(Color.white).frame(width: 60, height: 60)
            Image(user.imageName).resizable().frame(width: 60, height: 60).clipShape(Circle())
        }.offset(x: user.id < 3 ? 85 : 150).rotationEffect(.degrees(Double(user.id * 100)))
    }
}

struct UserViewForDrag: View {
    let user: User
    var body: some View {
        ZStack{
            Circle().fill(Color.white).frame(width: 60, height: 60)
            Image(user.imageName).resizable().frame(width: 60, height: 60).clipShape(Circle())
        }.offset(x: user.id < 3 ? 85 : 150).rotationEffect(.degrees(Double(user.id * 100)))
    }
}

struct User : Identifiable{
    let id: Int
    let name: String
    let imageName: String
    var isDragging: Bool = false
}

struct Data {
    static let data = [User(id: 0, name: "Alex", imageName: "p1")
                       ,User(id: 1, name: "Jennifer", imageName: "p2"),
                       User(id: 2, name: "Lisa", imageName: "p3"),
                       User(id: 3, name: "Mike", imageName: "p4"),
                       User(id: 4, name: "Sandra", imageName: "p5"),
                       User(id: 5, name: "Travis", imageName: "p6"),
                       User(id: 6, name: "Alex", imageName: "p7"),
                       User(id: 7, name: "Mike", imageName: "p8"),
                       User(id: 8, name: "Lisa", imageName: "p9")]
}

class UserManager: ObservableObject {
    @Published var userData = Data.data
    
    func changedUserDraggingValue(index: Int) {
        userData[index].isDragging.toggle()
    }
}

extension Color {
    static let background = Color.init(red: 1, green: 246/255, blue: 1)
    
    static let cardStart = Color.init(red: 11/255, green: 19/255, blue: 2/255)
    
    static let cardEnd = Color.init(red: 48/255, green: 53/255, blue: 27/255)
    
    static let cardLinear = LinearGradient(gradient: Gradient(colors: [cardStart, cardEnd]), startPoint: .leading, endPoint: .trailing)
    
    static let logoLinear = LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black]), startPoint: .bottomLeading, endPoint: .top)
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
