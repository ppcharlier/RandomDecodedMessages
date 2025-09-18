import SwiftUI

// MARK: - Votre code intégré
// J'ai intégré votre classe `RandomMessagesGenerator` ici pour qu'elle soit utilisable par la nouvelle vue.
class RandomMessagesGenerator {

    let charVersion: String = "0.1"
    var messageFromUser: String = "[message]"
    var outputMessage: String = "[output]"

    enum ChartType {
        case type1
        case type2
    }
    
    var charChart = [[ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
                     [ "A", "B", "C", "D", "E", "F", "G", "H", "I", "J"],
                     [ "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"],
                     [ "U", "V", "W", "X", "Y", "Z", "a", "b" ,"c", "d"],
                     [ "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"],
                     [ "o", "p", "q", "r", "s", "t", "u", "v", "w", "x"],
                     [ "y", "z", "?", ",", ".", ";", "/", ":", "+", "="],
                     [ "-", "*", "/", "(", ")", "{", "}", "<", ">", "["],
                     [ "]", " ", "\\", "#", "@", "&", " ", " ", "^", "¨"],
                     [  "%", "£", "€", "°", "\'", "\"", "_", "\t", "\n", "~"]
    ]

    func retrieveText() -> String {
        var message_string : String = ""
        var message_add: String
        var remIter: Int = .random(in: 1...3)
        repeat {
            arc4random_stir()
            message_add = String(arc4random())
            message_string += message_add
            remIter -= 1
        } while remIter > 0
        return "\(message_string)"
    }
    
    func correspondancePerChart(message: String, charChart: [[String]]) -> String {
        var chartSelect = true
        var message_trad: String = ""
        var subchart: [String] =  charChart[9]

        for (index, a) in message.enumerated() {
            if chartSelect || index == message.count-1 {
                if let digit = Int(String(a)) {
                    subchart = charChart[digit]
                } else {
                    subchart = ["?", "?", "?", "?", "?", "?", "?", "?", "?", "?"]
                }
            }

            if !chartSelect || index == message.count-1, let b = Int(String(a)) {
                message_trad += subchart[b]
            }
            chartSelect = !chartSelect
        }
        return message_trad
    }
}


// MARK: - Data Models

struct DecodingResult: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let userQuery: String
    let numbers: [UInt64]
    let decodedASCII: String
    let decodedUTF8: String
    let longestUTF8Sequence: String
    let longestUTF8StartBit: Int
    let longestUTF8ByteLength: Int
    var rating: Int = 0
}


// MARK: - Bit Helpers

struct BitStream {
    private let numbers: [UInt64]
    private var numberIndex = 0
    private var bitIndex = 0

    init(numbers: [UInt64]) { self.numbers = numbers }

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
            if bitIndex == 64 { bitIndex = 0; numberIndex += 1 }
        }
        return result
    }
}

struct BitBuffer {
    let numbers: [UInt64]
    let totalBits: Int

    init(numbers: [UInt64]) { self.numbers = numbers; self.totalBits = numbers.count * 64 }

    func read(bits count: Int, from bitOffset: Int) -> UInt64? {
        guard count > 0 && count <= 64, bitOffset >= 0, (bitOffset + count) <= totalBits else { return nil }
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
            if currentBitIndexInNumber == 64 { currentBitIndexInNumber = 0; currentNumberIndex += 1 }
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

// MARK: - Vue de Détail (Oracle)

struct DecodingDetailView: View {
    @Binding var result: DecodingResult

    var body: some View {
        List {
            Section(header: Text("Votre Requête")) {
                Text(result.userQuery.isEmpty ? "[Aucune requête spécifiée]" : result.userQuery)
                    .font(.headline).foregroundColor(result.userQuery.isEmpty ? .secondary : .primary).italic()
            }
            
            Section(header: Text("Évaluation de la Compréhension")) {
                HStack { Spacer(); StarRatingView(rating: $result.rating); Spacer() }.padding(.vertical)
            }
            
            Section(header: Text("Plus longue séquence UTF-8 lisible ('Réponse')")) {
                if result.longestUTF8Sequence.isEmpty {
                    Text("Aucune séquence significative trouvée.").foregroundColor(.secondary)
                } else {
                    Text("\"\(result.longestUTF8Sequence)\"").font(.system(.title3, design: .serif).bold()).padding(.bottom, 4)
                    HStack { Image(systemName: "mappin.and.ellipse"); Text("Position de départ : bit N°\(result.longestUTF8StartBit)") }.font(.subheadline).foregroundColor(.secondary)
                    HStack { Image(systemName: "ruler"); Text("Longueur : \(result.longestUTF8ByteLength) octets (\(result.longestUTF8ByteLength * 8) bits)") }.font(.subheadline).foregroundColor(.secondary)
                }
            }

            Section(header: Text("Décodage Linéaire (depuis le début)")) { Text(result.decodedUTF8).font(.system(.body, design: .default)) }
            
            Section(header: Text("Nombres Aléatoires (Hexadécimal)")) {
                Text(formatNumbers(result.numbers)).font(.system(.body, design: .monospaced))
                    .contextMenu { Button(action: { UIPasteboard.general.string = formatNumbers(result.numbers) }) { Label("Copier", systemImage: "doc.on.doc") } }
            }
        }.listStyle(InsetGroupedListStyle()).navigationTitle(Text(result.timestamp, style: .time)).navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatNumbers(_ numbers: [UInt64]) -> String { return numbers.map { String(format: "0x%016llX", $0) }.joined(separator: "\n") }
}


// MARK: - Vue Principale (Oracle)

struct ContentView: View {
    @State private var history: [DecodingResult] = []
    @State private var isProcessing = false
    @State private var userQuery: String = ""
    
    private var dateFormatter: DateFormatter { let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    TextField("Écrivez une phrase ou une question ici...", text: $userQuery, axis: .vertical)
                        .padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3)
                    HStack {
                        Button(action: generateAndDecode) { Label("Générer une Réponse", systemImage: "wand.and.stars").font(.headline) }
                        .buttonStyle(.borderedProminent).tint(.blue).disabled(isProcessing)
                        if isProcessing { ProgressView().padding(.leading, 10) }
                    }
                }.padding().background(Color(.systemGroupedBackground))

                if history.isEmpty {
                    VStack { Spacer(); Text("Aucun historique.").font(.title2).foregroundColor(.secondary); Text("Écrivez une phrase et appuyez sur 'Générer' pour commencer.").foregroundColor(.secondary); Spacer() }
                } else {
                    List {
                        Section(header: Text("Historique des analyses")) {
                            ForEach($history) { $result in
                                NavigationLink(destination: DecodingDetailView(result: $result)) { historyRow(for: result) }
                            }.onDelete(perform: deleteHistoryItem)
                        }
                    }.listStyle(InsetGroupedListStyle())
                }
            }.navigationTitle("Oracle de Bits").toolbar { EditButton() }
        }
    }
    
    @ViewBuilder private func historyRow(for result: DecodingResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.timestamp, formatter: dateFormatter).font(.caption).foregroundColor(.secondary)
            Text(result.userQuery.isEmpty ? "[Requête vide]" : result.userQuery).font(.headline.italic()).lineLimit(2)
            HStack {
                Text(result.longestUTF8Sequence.isEmpty ? "[Aucune réponse trouvée]" : "Réponse : \"\(result.longestUTF8Sequence)\"").font(.system(.body, design: .monospaced)).lineLimit(2).foregroundColor(.primary)
                Spacer()
                if result.rating > 0 { HStack(spacing: 2) { Text("\(result.rating)").bold(); Image(systemName: "star.fill") }.font(.caption).foregroundColor(.yellow) }
            }
        }.padding(.vertical, 6)
    }

    private func deleteHistoryItem(at offsets: IndexSet) { history.remove(atOffsets: offsets) }

    private func generateAndDecode() {
        isProcessing = true
        let queryForThisRun = userQuery
        DispatchQueue.global(qos: .userInitiated).async {
            let sequenceLength = Int.random(in: 8...15)
            let numbers = (0..<sequenceLength).map { _ in UInt64.random(in: .min ... .max) }
            let utf8Result = decodeToUTF8(from: numbers)
            let longestSequenceResult = findLongestUTF8Sequence(from: numbers)
            DispatchQueue.main.async {
                let newResult = DecodingResult(timestamp: Date(), userQuery: queryForThisRun, numbers: numbers, decodedASCII: "", decodedUTF8: utf8Result, longestUTF8Sequence: longestSequenceResult.sequence, longestUTF8StartBit: longestSequenceResult.startBit, longestUTF8ByteLength: longestSequenceResult.byteLength)
                history.insert(newResult, at: 0)
                isProcessing = false
                userQuery = ""
            }
        }
    }
    
    private func findLongestUTF8Sequence(from numbers: [UInt64]) -> (sequence: String, startBit: Int, byteLength: Int) {
        let buffer = BitBuffer(numbers: numbers)
        var overallBestSequence = ""; var overallBestStartBit = 0
        for startBit in 0..<(buffer.totalBits - 7) {
            var currentBytes: [UInt8] = []; var longestValidStringForThisStart = ""
            for byteIndex in 0... {
                let currentBitOffset = startBit + (byteIndex * 8)
                guard let byteValue = buffer.read(bits: 8, from: currentBitOffset) else { break }
                currentBytes.append(UInt8(truncatingIfNeeded: byteValue))
                let testString = String(decoding: currentBytes, as: UTF8.self)
                if !testString.contains("\u{FFFD}") { longestValidStringForThisStart = testString } else { break }
            }
            if longestValidStringForThisStart.count > overallBestSequence.count { overallBestSequence = longestValidStringForThisStart; overallBestStartBit = startBit }
        }
        return (overallBestSequence, overallBestStartBit, overallBestSequence.utf8.count)
    }

    private func decodeToUTF8(from numbers: [UInt64]) -> String {
        var bitStream = BitStream(numbers: numbers); var byteArray: [UInt8] = []
        while let byteValue = bitStream.read(bits: 8) { byteArray.append(UInt8(truncatingIfNeeded: byteValue)) }
        return String(decoding: byteArray, as: UTF8.self)
    }
}

// MARK: - NOUVELLE VUE : Flux Continu (Mise à jour)

struct ContinuousDecodingView: View {
    @State private var decodedMessages: String = ""
    @State private var isDecoding = false
    @State private var messageCount = 0
    @State private var decodingTask: Task<Void, Never>?

    @State private var userQuery: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private let generator = RandomMessagesGenerator()

    var body: some View {
        VStack(spacing: 0) {
            // --- Panneau de contrôle et de statistiques ---
            VStack(spacing: 12) {
                TextField("Formez vos pensées ici... le flux s'arrêtera.", text: $userQuery, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .lineLimit(1...3)
                    .tint(.orange)

                HStack {
                    if isTextFieldFocused {
                        Label("Flux en pause", systemImage: "pause.circle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                    } else {
                        Text("Messages Générés : \(messageCount)").font(.headline)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            // --- Zone d'affichage des messages ---
            ScrollViewReader { proxy in
                ScrollView {
                    Text(decodedMessages)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("bottom")
                }
                .onChange(of: decodedMessages) { _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }

            // --- Bouton de contrôle ---
            Button(action: toggleDecoding) {
                Label(isDecoding ? "Arrêter le Flux" : "Démarrer le Flux", systemImage: isDecoding ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(isDecoding ? Color.red : Color.green)
            .foregroundColor(.white)
            .buttonStyle(.borderedProminent)
            .tint(isDecoding ? .red : .green)
        }
        .navigationTitle("Flux Continu")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isTextFieldFocused = false
        }
        // MODIFICATION ICI : Ajout de la logique pour insérer la pensée de l'utilisateur
        .onChange(of: isTextFieldFocused) { isFocused in
            if !isFocused && !userQuery.isEmpty {
                // S'exécute quand l'utilisateur quitte le champ de texte
                let formattedQuery = "\n> [PENSÉE] : \(userQuery)\n---\n"
                decodedMessages.append(formattedQuery)
                userQuery = "" // Vide le champ de texte
            }
        }
    }

    private func toggleDecoding() {
        isDecoding.toggle()
        if isDecoding {
            startDecoding()
        } else {
            stopDecoding()
        }
    }

    private func startDecoding() {
        decodingTask = Task {
            while !Task.isCancelled {
                let isFocused = await MainActor.run { isTextFieldFocused }
                if isFocused {
                    do {
                        try await Task.sleep(nanoseconds: 500_000_000)
                        continue
                    } catch { break }
                }
                
                let rawText = generator.retrieveText()
                let decodedText = generator.correspondancePerChart(message: rawText, charChart: generator.charChart)
                
                await MainActor.run {
                    messageCount += 1
                    decodedMessages.append("\(decodedText)\n---\n")
                }
                
                do {
                    try await Task.sleep(nanoseconds: 100_000_000)
                } catch { break }
            }
        }
    }

    private func stopDecoding() {
        decodingTask?.cancel()
        decodingTask = nil
    }
}


// MARK: - SwiftUI App Entry Point

@main
struct NumberDecoderApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Oracle", systemImage: "wand.and.stars")
                    }
                
                NavigationView {
                    ContinuousDecodingView()
                }
                .tabItem {
                    Label("Flux Continu", systemImage: "infinity.circle.fill")
                }
            }
        }
    }
}

