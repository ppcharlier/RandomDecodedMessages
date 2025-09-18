import SwiftUI

// MARK: - Data Models

struct DecodingResult: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let userQuery: String // Champ ajouté pour la phrase de l'utilisateur
    let numbers: [UInt64]
    let decodedASCII: String
    let decodedUTF8: String
    
    let longestUTF8Sequence: String
    let longestUTF8StartBit: Int
    let longestUTF8ByteLength: Int

    var rating: Int = 0
}


// MARK: - Bit Helpers

/// Lit un flux de bits de manière séquentielle, comme une lecture de fichier.
struct BitStream {
    private let numbers: [UInt64]
    private var numberIndex = 0
    private var bitIndex = 0

    init(numbers: [UInt64]) {
        self.numbers = numbers
    }

    mutating func read(bits count: Int) -> UInt64? {
        guard count > 0 && count <= 64 else { return nil }
        let totalBitsAvailable = (numbers.count - numberIndex) * 64 - bitIndex
        guard totalBitsAvailable >= count else { return nil }

        var result: UInt64 = 0
        var bitsRead = 0

        while bitsRead < count {
            guard numberIndex < numbers.count else { break }
            let currentNumber = numbers[numberIndex]
            let bitsRemainingInCurrentNumber = 64 - bitIndex
            let bitsToReadNow = min(count - bitsRead, bitsRemainingInCurrentNumber)
            let mask: UInt64 = (bitsToReadNow == 64) ? .max : (1 << bitsToReadNow) - 1
            let extractedBits = (currentNumber >> bitIndex) & mask
            result |= (extractedBits << bitsRead)
            bitsRead += bitsToReadNow
            bitIndex += bitsToReadNow
            if bitIndex == 64 {
                bitIndex = 0
                numberIndex += 1
            }
        }
        return result
    }
}

/// Permet de lire des bits à partir de n'importe quelle position arbitraire (accès aléatoire).
struct BitBuffer {
    let numbers: [UInt64]
    let totalBits: Int

    init(numbers: [UInt64]) {
        self.numbers = numbers
        self.totalBits = numbers.count * 64
    }

    func read(bits count: Int, from bitOffset: Int) -> UInt64? {
        guard count > 0 && count <= 64 else { return nil }
        guard bitOffset >= 0 && (bitOffset + count) <= totalBits else { return nil }

        var result: UInt64 = 0
        var bitsRead = 0
        var currentNumberIndex = bitOffset / 64
        var currentBitIndexInNumber = bitOffset % 64

        while bitsRead < count {
            guard currentNumberIndex < numbers.count else { break }
            let currentNumber = numbers[currentNumberIndex]
            let bitsRemainingInCurrentNumber = 64 - currentBitIndexInNumber
            let bitsToReadNow = min(count - bitsRead, bitsRemainingInCurrentNumber)
            let mask: UInt64 = (bitsToReadNow == 64) ? .max : (1 << bitsToReadNow) - 1
            let extractedBits = (currentNumber >> currentBitIndexInNumber) & mask
            result |= (extractedBits << bitsRead)
            bitsRead += bitsToReadNow
            currentBitIndexInNumber += bitsToReadNow
            if currentBitIndexInNumber == 64 {
                currentBitIndexInNumber = 0
                currentNumberIndex += 1
            }
        }
        return result
    }
}


// MARK: - Reusable UI Components

struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { number in
                Image(systemName: number > rating ? "star" : "star.fill")
                    .resizable().scaledToFit().foregroundColor(.yellow).frame(width: 30, height: 30)
                    .onTapGesture { rating = (number == rating) ? 0 : number }
            }
        }
    }
}

// MARK: - Detail View

struct DecodingDetailView: View {
    @Binding var result: DecodingResult

    var body: some View {
        List {
            // NOUVELLE SECTION pour la requête de l'utilisateur
            Section(header: Text("Votre Requête")) {
                Text(result.userQuery.isEmpty ? "[Aucune requête spécifiée]" : result.userQuery)
                    .font(.headline)
                    .foregroundColor(result.userQuery.isEmpty ? .secondary : .primary)
                    .italic()
            }
            
            Section(header: Text("Évaluation de la Compréhension")) {
                HStack {
                    Spacer()
                    StarRatingView(rating: $result.rating)
                    Spacer()
                }.padding(.vertical)
            }
            
            Section(header: Text("Plus longue séquence UTF-8 lisible ('Réponse')")) {
                if result.longestUTF8Sequence.isEmpty {
                    Text("Aucune séquence significative trouvée.").foregroundColor(.secondary)
                } else {
                    Text("\"\(result.longestUTF8Sequence)\"")
                        .font(.system(.title3, design: .serif).bold())
                        .padding(.bottom, 4)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Position de départ : bit N°\(result.longestUTF8StartBit)")
                    }.font(.subheadline).foregroundColor(.secondary)
                    
                    HStack {
                         Image(systemName: "ruler")
                         Text("Longueur : \(result.longestUTF8ByteLength) octets (\(result.longestUTF8ByteLength * 8) bits)")
                    }.font(.subheadline).foregroundColor(.secondary)
                }
            }

            Section(header: Text("Décodage Linéaire (depuis le début)")) {
                Text(result.decodedUTF8).font(.system(.body, design: .default))
            }
            
            Section(header: Text("Nombres Aléatoires (Hexadécimal)")) {
                Text(formatNumbers(result.numbers))
                    .font(.system(.body, design: .monospaced))
                    .contextMenu {
                        Button(action: { UIPasteboard.general.string = formatNumbers(result.numbers) }) {
                            Label("Copier", systemImage: "doc.on.doc")
                        }
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text(result.timestamp, style: .time))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatNumbers(_ numbers: [UInt64]) -> String {
        return numbers.map { String(format: "0x%016llX", $0) }.joined(separator: "\n")
    }
}


// MARK: - Main ContentView (History List)

struct ContentView: View {
    @State private var history: [DecodingResult] = []
    @State private var isProcessing = false
    @State private var userQuery: String = "" // État pour le champ de texte
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Panneau de contrôle avec champ de texte ---
                VStack(spacing: 12) {
                    TextField("Écrivez une phrase ou une question ici...", text: $userQuery, axis: .vertical)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .lineLimit(1...3)

                    HStack {
                        Button(action: generateAndDecode) {
                            Label("Générer une Réponse", systemImage: "wand.and.stars")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent).tint(.blue).disabled(isProcessing)
                        if isProcessing { ProgressView().padding(.leading, 10) }
                    }
                }
                .padding().background(Color(.systemGroupedBackground))

                // --- Historique ---
                if history.isEmpty {
                    VStack {
                        Spacer()
                        Text("Aucun historique.").font(.title2).foregroundColor(.secondary)
                        Text("Écrivez une phrase et appuyez sur 'Générer' pour commencer.").foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        Section(header: Text("Historique des analyses")) {
                            ForEach($history) { $result in
                                NavigationLink(destination: DecodingDetailView(result: $result)) {
                                    historyRow(for: result)
                                }
                            }.onDelete(perform: deleteHistoryItem)
                        }
                    }.listStyle(InsetGroupedListStyle())
                }
            }.toolbar {
                EditButton()
            }
            .navigationTitle("Oracle de Bits")
            
        }
    }
    
    @ViewBuilder
    private func historyRow(for result: DecodingResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.timestamp, formatter: dateFormatter).font(.caption).foregroundColor(.secondary)
            Text(result.userQuery.isEmpty ? "[Requête vide]" : result.userQuery)
                .font(.headline.italic())
                .lineLimit(2)
            
            HStack {
                Text(result.longestUTF8Sequence.isEmpty ? "[Aucune réponse trouvée]" : "Réponse : \"\(result.longestUTF8Sequence)\"")
                    .font(.system(.body, design: .monospaced)).lineLimit(2).foregroundColor(.primary)
                Spacer()
                if result.rating > 0 {
                    HStack(spacing: 2) {
                        Text("\(result.rating)").bold()
                        Image(systemName: "star.fill")
                    }.font(.caption).foregroundColor(.yellow)
                }
            }
        }.padding(.vertical, 6)
    }

    // MARK: - Logic Functions
    
    private func deleteHistoryItem(at offsets: IndexSet) { history.remove(atOffsets: offsets) }

    private func generateAndDecode() {
        isProcessing = true
        let queryForThisRun = userQuery // Capturer la requête actuelle
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sequenceLength = Int.random(in: 8...15)
            let numbers = (0..<sequenceLength).map { _ in UInt64.random(in: .min ... .max) }

            let utf8Result = decodeToUTF8(from: numbers)
            let longestSequenceResult = findLongestUTF8Sequence(from: numbers)

            DispatchQueue.main.async {
                let newResult = DecodingResult(
                    timestamp: Date(), userQuery: queryForThisRun, numbers: numbers,
                    decodedASCII: "", // ASCII n'est plus pertinent ici, on pourrait le supprimer
                    decodedUTF8: utf8Result,
                    longestUTF8Sequence: longestSequenceResult.sequence,
                    longestUTF8StartBit: longestSequenceResult.startBit,
                    longestUTF8ByteLength: longestSequenceResult.byteLength
                )
                history.insert(newResult, at: 0)
                isProcessing = false
                userQuery = "" // Optionnel: vider le champ après génération
            }
        }
    }
    
    private func findLongestUTF8Sequence(from numbers: [UInt64]) -> (sequence: String, startBit: Int, byteLength: Int) {
        let buffer = BitBuffer(numbers: numbers)
        var overallBestSequence = ""
        var overallBestStartBit = 0

        for startBit in 0..<(buffer.totalBits - 7) {
            var currentBytes: [UInt8] = []
            var longestValidStringForThisStart = ""
            
            for byteIndex in 0... {
                let currentBitOffset = startBit + (byteIndex * 8)
                guard let byteValue = buffer.read(bits: 8, from: currentBitOffset) else { break }
                currentBytes.append(UInt8(truncatingIfNeeded: byteValue))
                let testString = String(decoding: currentBytes, as: UTF8.self)
                
                if !testString.contains("\u{FFFD}") {
                    longestValidStringForThisStart = testString
                } else { break }
            }

            if longestValidStringForThisStart.count > overallBestSequence.count {
                overallBestSequence = longestValidStringForThisStart
                overallBestStartBit = startBit
            }
        }
        return (overallBestSequence, overallBestStartBit, overallBestSequence.utf8.count)
    }

    private func decodeToUTF8(from numbers: [UInt64]) -> String {
        var bitStream = BitStream(numbers: numbers); var byteArray: [UInt8] = []
        while let byteValue = bitStream.read(bits: 8) {
            byteArray.append(UInt8(truncatingIfNeeded: byteValue))
        }
        return String(decoding: byteArray, as: UTF8.self)
    }
}

// MARK: - SwiftUI App Entry Point

@main
struct NumberDecoderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}



// MARK: - SwiftUI Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
