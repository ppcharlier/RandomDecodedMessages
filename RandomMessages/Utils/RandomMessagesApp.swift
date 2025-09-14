import SwiftUI

// MARK: - Data Models

struct DecodingResult: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let numbers: [UInt64]
    let decodedASCII: String
    let decodedUTF8: String
    var rating: Int = 0 // 0 = non noté, 1-5 = note
}


// MARK: - BitStream Helper

/// Une structure pour lire un flux de bits à partir d'un tableau de nombres `UInt64`.
/// Elle traite le tableau comme une seule séquence continue de bits.
struct BitStream {
    private let numbers: [UInt64]
    private var numberIndex = 0
    private var bitIndex = 0 // Position du bit actuel dans le `currentNumber` (0-63)

    /// Initialise le flux de bits avec un tableau de nombres.
    init(numbers: [UInt64]) {
        self.numbers = numbers
    }

    /// Lit un nombre spécifié de bits depuis le flux.
    /// - Parameter count: Le nombre de bits à lire (doit être entre 1 et 64).
    /// - Returns: Une valeur `UInt64` contenant les bits lus, ou `nil` s'il n'y a pas assez de bits restants.
    mutating func read(bits count: Int) -> UInt64? {
        // Valider que l'on peut lire le nombre de bits demandé.
        guard count > 0 && count <= 64 else { return nil }
        
        let totalBitsAvailable = (numbers.count - numberIndex) * 64 - bitIndex
        guard totalBitsAvailable >= count else { return nil }

        var result: UInt64 = 0
        var bitsRead = 0

        while bitsRead < count {
            // S'assurer que nous ne sommes pas à la fin du tableau de nombres.
            guard numberIndex < numbers.count else { break }

            let currentNumber = numbers[numberIndex]
            let bitsRemainingInCurrentNumber = 64 - bitIndex
            let bitsToReadNow = min(count - bitsRead, bitsRemainingInCurrentNumber)

            let mask: UInt64 = (bitsToReadNow == 64) ? UInt64.max : (1 << bitsToReadNow) - 1
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


// MARK: - Reusable UI Components

struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { number in
                Image(systemName: number > rating ? "star" : "star.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.yellow)
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        if number == rating {
                            rating = 0 // Permet d'annuler la note
                        } else {
                            rating = number
                        }
                    }
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
                }
                .padding(.vertical)
            }
            
            Section(header: Text("Nombres Aléatoires (UInt64 en Hexadécimal)")) {
                Text(formatNumbers(result.numbers))
                    .font(.system(.body, design: .monospaced))
                    .contextMenu {
                        Button(action: { UIPasteboard.general.string = formatNumbers(result.numbers) }) {
                            Label("Copier", systemImage: "doc.on.doc")
                        }
                    }
            }

            Section(header: Text("Décodage ASCII (caractères imprimables)")) {
                 if result.decodedASCII.isEmpty {
                    Text("Aucun caractère ASCII imprimable trouvé.").foregroundColor(.secondary)
                } else {
                    Text(result.decodedASCII).font(.system(.body, design: .serif))
                }
            }

            Section(header: Text("Décodage UTF-8")) {
                Text(result.decodedUTF8).font(.system(.body, design: .default))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text(result.timestamp, style: .relative))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Formate un tableau de `UInt64` en une chaîne de caractères hexadécimale lisible.
    private func formatNumbers(_ numbers: [UInt64]) -> String {
        return numbers.map { String(format: "0x%016llX", $0) }.joined(separator: "\n")
    }
}


// MARK: - Main ContentView (History List)

struct ContentView: View {
    @State private var history: [DecodingResult] = []
    @State private var isProcessing = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Panneau de contrôle ---
                HStack {
                    Button(action: generateAndDecode) {
                        Label("Générer et Décoder", systemImage: "arrow.triangle.2.circlepath.circle")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isProcessing)
                    
                    if isProcessing {
                        ProgressView().padding(.leading, 10)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))

                // --- Affichage de l'historique ---
                if history.isEmpty {
                    VStack {
                        Spacer()
                        Text("Aucun historique.").font(.title2).foregroundColor(.secondary)
                        Text("Appuyez sur le bouton pour commencer.").foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        Section(header: Text("Historique des décodages")) {
                            ForEach($history) { $result in
                                NavigationLink(destination: DecodingDetailView(result: $result)) {
                                    historyRow(for: result)
                                }
                            }
                            .onDelete(perform: deleteHistoryItem)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Décodeur de Bits")
            .toolbar { EditButton() }
        }
    }
    
    @ViewBuilder
    private func historyRow(for result: DecodingResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(result.timestamp, formatter: dateFormatter)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.decodedUTF8.isEmpty ? "[Aucun contenu décodable]" : result.decodedUTF8)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if result.rating > 0 {
                HStack(spacing: 2) {
                    Text("\(result.rating)")
                    Image(systemName: "star.fill")
                }
                .font(.caption.bold())
                .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Logic Functions
    
    private func deleteHistoryItem(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
    }

    private func generateAndDecode() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sequenceLength = Int.random(in: 4...10)
            let numbers = (0..<sequenceLength).map { _ in UInt64.random(in: .min ... .max) }

            let asciiResult = decodeToASCII(from: numbers)
            let utf8Result = decodeToUTF8(from: numbers)

            DispatchQueue.main.async {
                let newResult = DecodingResult(
                    timestamp: Date(),
                    numbers: numbers,
                    decodedASCII: asciiResult,
                    decodedUTF8: utf8Result
                )
                history.insert(newResult, at: 0)
                isProcessing = false
            }
        }
    }

    private func decodeToASCII(from numbers: [UInt64]) -> String {
        var bitStream = BitStream(numbers: numbers)
        var result = ""
        while let byteValue = bitStream.read(bits: 8) {
            let byte = UInt8(truncatingIfNeeded: byteValue)
            if byte >= 32 && byte <= 126 {
                result.append(Character(Unicode.Scalar(byte)))
            }
        }
        return result
    }

    private func decodeToUTF8(from numbers: [UInt64]) -> String {
        var bitStream = BitStream(numbers: numbers)
        var byteArray: [UInt8] = []
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
