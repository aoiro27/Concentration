//
//  ContentView.swift
//  Concentration
//
//  Created by aoiro on 2025/07/13.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ContentView: View {
    @State private var cards: [Card] = []
    @State private var selectedCards: [Int] = []
    @State private var matchedPairs: Set<Int> = []
    @State private var gameCompleted = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingPhotoSelection = false
    @State private var gameStarted = false
    @State private var isChecking = false
    @State private var bgmPlayer: AVAudioPlayer?
    
    let emojis = ["🐶", "🐱", "🐰", "🐼", "🐨", "🐯", "🦁", "🐸", "🐵", "🐷", "🐮", "🐷"]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20)

            if !gameStarted {
                // 写真選択画面
                Text("しきしろ絵あわせ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                VStack(spacing: 30) {
                    Text("写真を選んでね！")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("\(selectedPhotos.count)/8枚選択済み")
                        .font(.headline)
                        .foregroundColor(.orange)

                    // 選択された写真のプレビュー
                    if !selectedPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<selectedPhotos.count, id: \.self) { index in
                                    Image(uiImage: selectedPhotos[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(
                                            Button(action: {
                                                selectedPhotos.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                            }
                                            .offset(x: 35, y: -35),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    HStack(spacing: 30) {
                        Button(action: {
                            showingActionSheet = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("写真を追加")
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        }
                        .disabled(selectedPhotos.count >= 8)
                        .confirmationDialog("写真を選択", isPresented: $showingActionSheet, titleVisibility: .visible) {
                            Button("カメラで撮影") { showingCamera = true }
                            Button("フォトライブラリから選択") { showingPhotoPicker = true }
                            Button("キャンセル", role: .cancel) {}
                        }

                        Button(action: {
                            if selectedPhotos.count >= 8 {
                                startGame()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("ゲーム開始")
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(selectedPhotos.count >= 8 ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        }
                        .disabled(selectedPhotos.count < 8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // ゲーム画面
                Text("しきしろ絵あわせ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .frame(height: 48)

                HStack {
                    Text("見つけたペア: \(matchedPairs.count)")
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                    Text("残り: \(cards.count / 2 - matchedPairs.count)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .frame(height: 32)

                GeometryReader { geometry in
                    let columns = 4
                    let rows = (cards.count + columns - 1) / columns
                    let spacing: CGFloat = 12
                    let verticalPadding: CGFloat = 48 + 32 + 60 + 24
                    let availableWidth = geometry.size.width - spacing * CGFloat(columns - 1)
                    let availableHeight = geometry.size.height - verticalPadding - spacing * CGFloat(rows - 1)

                    let cardWidth = availableWidth / CGFloat(columns)
                    let cardHeight = cardWidth * 1.5
                    let maxCardHeight = availableHeight / CGFloat(rows)
                    let finalCardHeight = min(cardHeight, maxCardHeight)
                    let finalCardWidth = finalCardHeight / 1.5

                    VStack {
                        Spacer(minLength: 0)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                            ForEach(0..<cards.count, id: \.self) { index in
                                CardView(card: cards[index])
                                    .frame(width: finalCardWidth, height: finalCardHeight)
                                    .onTapGesture {
                                        cardTapped(at: index)
                                    }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                HStack(spacing: 30) {
                    Button(action: {
                        resetGame()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("リセット")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(radius: 4)
                    }

                    Button(action: {
                        gameStarted = false
                        selectedPhotos.removeAll()
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("写真を変更")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(radius: 4)
                    }
                }
                .padding(.bottom, 24)
                .frame(height: 60)
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            setupGame()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImages: $selectedPhotos)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImages: $selectedPhotos)
        }
        .alert("おめでとう！", isPresented: $gameCompleted) {
            Button("もう一度遊ぶ") {
                resetGame()
            }
        } message: {
            Text("すべてのペアを見つけました！")
        }
    }
    
    private func setupGame() {
        cards = []
        // 選択された写真を使ってペアを作成
        let photoPairs = selectedPhotos + selectedPhotos
        cards = photoPairs.shuffled().enumerated().map { index, photo in
            Card(id: index, emoji: "", isFaceUp: false, isMatched: false, frontImage: photo)
        }
        selectedCards = []
        matchedPairs = []
        gameCompleted = false
    }
    
    private func startGame() {
        setupGame()
        gameStarted = true
        playBGM()
    }
    
    private func cardTapped(at index: Int) {
        guard !cards[index].isMatched && !cards[index].isFaceUp else { return }
        guard !isChecking else { return } // 判定中は何もしない

        cards[index].isFaceUp = true
        playFlipSound()

        if selectedCards.count == 0 {
            selectedCards.append(index)
        } else if selectedCards.count == 1 {
            selectedCards.append(index)
            isChecking = true
            checkForMatch()
        }
    }
    
    private func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("音声ファイルの再生に失敗しました: \(error)")
        }
    }

    private func playMatchSound() {
        playSound(named: "match")
    }

    private func playMissSound() {
        playSound(named: "miss")
    }

    private func playClearSound() {
        playSound(named: "clear")
    }
    
    private func playFlipSound() {
        playSound(named: "flip")
    }

    private func playBGM() {
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else { return }
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // ループ再生
            bgmPlayer?.volume = 0.5
            bgmPlayer?.play()
        } catch {
            print("BGMの再生に失敗しました: \(error)")
        }
    }

    private func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }
    
    private func checkForMatch() {
        let firstIndex = selectedCards[0]
        let secondIndex = selectedCards[1]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 写真の比較（UIImageの比較は難しいので、インデックスで比較）
            let firstPhotoIndex = selectedPhotos.firstIndex(of: cards[firstIndex].frontImage!) ?? -1
            let secondPhotoIndex = selectedPhotos.firstIndex(of: cards[secondIndex].frontImage!) ?? -1
            
            if firstPhotoIndex == secondPhotoIndex && firstPhotoIndex != -1 {
                // マッチした場合
                cards[firstIndex].isMatched = true
                cards[secondIndex].isMatched = true
                matchedPairs.insert(firstPhotoIndex)
                playMatchSound()
                
                if matchedPairs.count == cards.count / 2 {
                    playClearSound()
                    gameCompleted = true
                    stopBGM()
                }
            } else {
                // マッチしなかった場合
                cards[firstIndex].isFaceUp = false
                cards[secondIndex].isFaceUp = false
                playMissSound()
            }
            selectedCards = []
            isChecking = false
        }
    }
    
    private func resetGame() {
        if gameStarted {
            setupGame()
            stopBGM()
        }
    }
}

struct Card: Identifiable {
    let id: Int
    let emoji: String
    var isFaceUp: Bool
    var isMatched: Bool
    var frontImage: UIImage?
}

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            if card.isFaceUp {
                // 表（めくった時）: 子供の写真
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(radius: 3)
                
                if let frontImage = card.frontImage {
                    Image(uiImage: frontImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    // 写真が設定されていない場合は絵文字を表示
                    Text(card.emoji)
                        .font(.system(size: 40))
                }
            } else {
                // 裏（初期状態）: カラフルな背景
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(radius: 3)
                
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .opacity(card.isMatched ? 0.5 : 1.0)
        .scaleEffect(card.isMatched ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: card.isFaceUp)
        .animation(.easeInOut(duration: 0.3), value: card.isMatched)
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 8 - selectedImages.count
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            for result in results {
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        DispatchQueue.main.async {
                            if let uiImage = image as? UIImage {
                                self.parent.selectedImages.append(uiImage)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
