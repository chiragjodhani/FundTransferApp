//
//  PaymentView.swift
//  FundTransferApp
//
//  Created by Chirag's on 22/09/20.
//

import SwiftUI

struct PaymentView: View {
    public var viewSpace: Namespace.ID
    @ObservedObject var dragDrop:UserDragDrop
    @ObservedObject var input = PaymentInput()
    @State var config = PaymentConfig()
    var body: some View {
        ZStack {
            Rectangle().onTapGesture {
                withAnimation {
                    dragDrop.dragDropConfig.isDroppedOnPayment = false
                }
            }
            VStack {
                Spacer(minLength: config.topPadding / 2)
                CreditCardView(showCreditCard: $config.showCreditCard)
                Spacer(minLength: config.topPadding / 2)
                RoundedRectangle(cornerRadius: 25.0).fill(Color.background).matchedGeometryEffect(id: "viewID", in: viewSpace)
            }
            VStack(spacing: 30) {
                Spacer(minLength: config.showCreditCard ? 290 : 120)
                UserViewForDrag(user: dragDrop.pickedUser, width: 100).scaleEffect(config.startAnimation ? 1.0 : 0.0)
                Text("Transfer to ") + Text("\(dragDrop.pickedUser.name)").fontWeight(.heavy)
                HStack {
                    Text("$")
                    Text(input.amount)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 3, height: 45)
                        .opacity(config.blink ? 0.0 : 1.0)
                        .opacity(config.showCreditCard ? 0.0 : 1.0)
                        .onAppear{
                        withAnimation(Animation.linear(duration: 0.7).repeatForever()) {
                            config.blink.toggle()
                        }
                    }
                }.font(.system(size: 48, weight: .black))
                Spacer()
                
                PaymentCompletionView(config: $config, dragDrop: dragDrop)
                
                DescriptionView()
                    .opacity(config.showCreditCard ? 0.0 : 1.0)
                    .frame(height: config.showCreditCard ? 0.0 : 60.0)
                HStack {
                    NumberPadView(input: input)
                    PaymentAction(input: input, config: $config)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .padding(.horizontal)
                .padding(.bottom, 34)
                .offset(y: config.startAnimation ? 0.0 : 300)
                .opacity(config.showCreditCard ? 0.0 : 1.0)
                .frame(height: config.showCreditCard ? 0.0 : 280.0)
            }
        }.onAppear {
            withAnimation(Animation.linear(duration: 0.7)) {
                config.startAnimation = true
            }
        }
    }
}


struct DescriptionView: View {
    var body: some View {
        HStack {
            HStack {
                Text("🇱🇷").font(.system(size: 60)).fixedSize().frame(width: 30, height: 30).cornerRadius(15)
                Text("USD").font(.system(size: 20))
            }.padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white).cornerRadius(30)
            
            TextField("Say something", text: .constant("")).padding(.horizontal, 16)
                .padding(.vertical, 16).background(Color.white).cornerRadius(30)
        }.padding(.horizontal)
    }
}

struct PaymentAction: View {
    @ObservedObject var input: PaymentInput
    @Binding var config:PaymentConfig
    var body: some View {
        VStack {
            Button(action: {
                input.handleBackspace()
            }) {
                Image(systemName: "delete.left")
                    .font(.system(size: 24))
                    .padding(16)
                    .fixedSize()
                    .frame(width: 70)
            }
            Button(action: {
                withAnimation(.linear(duration: 0.7)) {
                    config.showCreditCard = true
                }
            }) {
                ZStack {
                    Rectangle().fill().frame(height: 200)
                    Text("SEND")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
        }.foregroundColor(.black)
    }
}

struct NumberPadView: View {
    let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["0", "", "."]
    ]
    @ObservedObject var input: PaymentInput
    var body: some View {
        VStack {
            ForEach(self.numbers, id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { number in
                        Button(action: {
                            input.handleNumbers(number: number)
                        }) {
                            Text(number).padding(12).fixedSize().frame(width: 70).foregroundColor(.black)
                        }
                    }
                }
            }
        }.font(.system(size: 28, weight: .bold)).padding(.leading, 8)
    }
}

class PaymentInput: ObservableObject {
    @Published var amount = ""
    
    func handleNumbers(number: String) {
        if amount.count < 7 {
            if number != "." {
                amount.append(number)
            }else {
                if !amount.contains(".") {
                    amount.append(number)
                }
            }
        }else {
            
        }
    }
    
    func handleBackspace() {
        if amount.count > 0 {
            amount.removeLast()
        }
    }
}

struct PaymentConfig {
    var blink = false
    var startAnimation = false
    var startRotationAnimation = false
    var showCreditCard = false
    var faceIDSuccess = false
    var topPadding: CGFloat = 200
    
}


struct CreditCardView: View {
    @Binding var showCreditCard: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.cardLinear)
            VStack(spacing: 16) {
                HStack {
                    Text("Credit Card").bold()
                    Spacer()
                    Image(systemName: "wave.3.right").font(.system(size: 30))
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "simcard.fill").font(.system(size: 40)).rotationEffect(.degrees(90))
                    Spacer()
                    Text("9456 8944 9456 8944").bold()
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Card Holder").bold()
                        Text("Dimest")
                    }.font(.system(size: 12))
                    Spacer()
                    Text("VISA").italic().bold().font(.system(size: 30))
                }
            }.padding(.horizontal)
            .foregroundColor(.white)
        }.frame(width: 300, height: showCreditCard ? 170 : 0.0)
        .opacity(showCreditCard ? 1.0 : 0.0)
    }
}

struct PaymentCompletionView: View {
    @Binding var config: PaymentConfig
    @ObservedObject var dragDrop:UserDragDrop
    var body: some View {
        ZStack {
            Button(action: {
                config.faceIDSuccess = true
                withAnimation(.linear(duration: 1.5)) {
                    config.startRotationAnimation = true
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).stroke(lineWidth: 4)
                    Image(systemName: "faceid")
                        .font(.system(size: 102))
                        .opacity(config.faceIDSuccess ? 0.0 : 1.0)
                }
                .rotationEffect(config.startRotationAnimation ? .degrees(240.0) : .degrees(0.0))
                .opacity(config.startRotationAnimation ? 0.0 : 1.0)
                .foregroundColor(.black)
            }
            
            Button(action: {
                withAnimation(.linear(duration: 1.5)) {
                    dragDrop.dragDropConfig.isDroppedOnPayment = false
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2,34]))
                        .scaleEffect(config.startRotationAnimation ? 1.4 : 1.2)
                        .rotationEffect(config.startRotationAnimation ? .degrees(0.0) : .degrees(-360.0))
                        .opacity(config.startRotationAnimation ? 0.0 : 1.0)
                    Circle().stroke(lineWidth: 4)
                    CheckmarkShape()
                        .trim(from: 0.0, to: config.startRotationAnimation ? 1.0 : 0.0)
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }.foregroundColor(.black)
            }
            .opacity(config.startRotationAnimation ? 1.0 : 0.0)
            
        }.frame(width: config.showCreditCard ? 100 : 0.0, height: config.showCreditCard ? 100 : 0.0).opacity(config.showCreditCard ? 1.0 : 0.0)
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 25, y: 50))
            path.addLine(to: CGPoint(x: 25, y: 50))
            path.addLine(to: CGPoint(x: 40, y: 65))
            path.addLine(to: CGPoint(x: 70, y: 35))
        }
    }
}
