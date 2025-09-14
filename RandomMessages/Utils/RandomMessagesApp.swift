import SwiftUI

// MARK: - Data Models

struct DecodingResult: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let numbers: [UInt64]
    let decodedASCII: String
    let decodedUTF8: String
    
    // Nouveaux champs pour la plus longue séquence
    let longestUTF8Sequence: String
    let longestUTF8StartBit: Int
    let longestUTF8ByteLength: Int

    var rating: Int = 0 // 0 = non noté, 1-5 = note
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
            Section(header: Text("Évaluation de la Compréhension")) {
                HStack {
                    Spacer()
                    StarRatingView(rating: $result.rating)
                    Spacer()
                }.padding(.vertical)
            }
            
            // NOUVELLE SECTION pour la plus longue séquence
            Section(header: Text("Plus longue séquence UTF-8 lisible")) {
                if result.longestUTF8Sequence.isEmpty {
                    Text("Aucune séquence significative trouvée.").foregroundColor(.secondary)
                } else {
                    Text("\"\(result.longestUTF8Sequence)\"")
                        .font(.system(.title3, design: .serif).bold())
                        .padding(.bottom, 4)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Position de départ : bit N°\(result.longestUTF8StartBit)")
                    }
                    .font(.subheadline).foregroundColor(.secondary)
                    
                    HStack {
                         Image(systemName: "ruler")
                         Text("Longueur : \(result.longestUTF8ByteLength) octets (\(result.longestUTF8ByteLength * 8) bits)")
                    }
                    .font(.subheadline).foregroundColor(.secondary)
                }
            }

            Section(header: Text("Décodage Linéaire (depuis le début)")) {
                Text(result.decodedUTF8).font(.system(.body, design: .default))
            }
            
            Section(header: Text("Décodage ASCII (caractères imprimables)")) {
                if result.decodedASCII.isEmpty {
                    Text("Aucun caractère ASCII imprimable trouvé.").foregroundColor(.secondary)
                } else {
                    Text(result.decodedASCII).font(.system(.body, design: .serif))
                }
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
        .navigationTitle(Text(result.timestamp, style: .relative))
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: generateAndDecode) {
                        Label("Générer et Analyser", systemImage: "magnifyingglass.circle")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent).tint(.blue).disabled(isProcessing)
                    if isProcessing { ProgressView().padding(.leading, 10) }
                }
                .padding().frame(maxWidth: .infinity).background(Color(.systemGroupedBackground))

                if history.isEmpty {
                    VStack {
                        Spacer()
                        Text("Aucun historique.").font(.title2).foregroundColor(.secondary)
                        Text("Appuyez sur 'Générer et Analyser' pour commencer.").foregroundColor(.secondary)
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
            }
            .navigationTitle("Analyseur de Bits").toolbar { EditButton() }
        }
    }
    
    @ViewBuilder
    private func historyRow(for result: DecodingResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(result.timestamp, formatter: dateFormatter).font(.headline)
                Text(result.longestUTF8Sequence.isEmpty ? "[Aucune séquence trouvée]" : result.longestUTF8Sequence)
                    .font(.system(.body, design: .monospaced)).lineLimit(2).foregroundColor(.secondary)
            }
            Spacer()
            if result.rating > 0 {
                HStack(spacing: 2) {
                    Text("\(result.rating)").bold()
                    Image(systemName: "star.fill")
                }.font(.caption).foregroundColor(.yellow)
            }
        }.padding(.vertical, 6)
    }

    // MARK: - Logic Functions
    
    private func deleteHistoryItem(at offsets: IndexSet) { history.remove(atOffsets: offsets) }

    private func generateAndDecode() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sequenceLength = Int.random(in: 5...12)
            let numbers = (0..<sequenceLength).map { _ in UInt64.random(in: .min ... .max) }

            // Décodages classiques
            let asciiResult = decodeToASCII(from: numbers)
            let utf8Result = decodeToUTF8(from: numbers)
            
            // Nouvelle recherche intensive
            let longestSequenceResult = findLongestUTF8Sequence(from: numbers)

            DispatchQueue.main.async {
                let newResult = DecodingResult(
                    timestamp: Date(), numbers: numbers,
                    decodedASCII: asciiResult, decodedUTF8: utf8Result,
                    longestUTF8Sequence: longestSequenceResult.sequence,
                    longestUTF8StartBit: longestSequenceResult.startBit,
                    longestUTF8ByteLength: longestSequenceResult.byteLength
                )
                history.insert(newResult, at: 0)
                isProcessing = false
            }
        }
    }
    
    /// NOUVELLE FONCTION : Recherche la plus longue sous-séquence UTF-8 valide
    private func findLongestUTF8Sequence(from numbers: [UInt64]) -> (sequence: String, startBit: Int, byteLength: Int) {
        let buffer = BitBuffer(numbers: numbers)
        var overallBestSequence = ""
        var overallBestStartBit = 0

        // Itérer à travers chaque position de bit de départ possible
        for startBit in 0..<(buffer.totalBits - 7) { // Il faut au moins 8 bits pour 1 octet
            var currentBytes: [UInt8] = []
            var longestValidStringForThisStart = ""
            
            // Essayer de lire de plus en plus d'octets à partir de ce point de départ
            for byteIndex in 0... {
                let currentBitOffset = startBit + (byteIndex * 8)
                guard let byteValue = buffer.read(bits: 8, from: currentBitOffset) else {
                    break // Fin du flux de bits
                }
                currentBytes.append(UInt8(truncatingIfNeeded: byteValue))
                
                // Essayer de décoder la séquence d'octets actuelle
                let testString = String(decoding: currentBytes, as: UTF8.self)
                
                // Si le décodage ne produit pas de caractère d'erreur (), la séquence est valide
                if !testString.contains("\u{FFFD}") {
                    longestValidStringForThisStart = testString
                } else {
                    // Le dernier octet a rendu la séquence invalide, on arrête pour ce point de départ
                    break
                }
            }

            // Si la meilleure chaîne pour ce point de départ est meilleure que la meilleure globale, on la garde
            // On privilégie la longueur en caractères, pas en octets.
            if longestValidStringForThisStart.count > overallBestSequence.count {
                overallBestSequence = longestValidStringForThisStart
                overallBestStartBit = startBit
            }
        }
        
        return (overallBestSequence, overallBestStartBit, overallBestSequence.utf8.count)
    }

    private func decodeToASCII(from numbers: [UInt64]) -> String {
        var bitStream = BitStream(numbers: numbers); var result = ""
        while let byteValue = bitStream.read(bits: 8) {
            let byte = UInt8(truncatingIfNeeded: byteValue)
            if byte >= 32 && byte <= 126 { result.append(Character(Unicode.Scalar(byte))) }
        }
        return result
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
