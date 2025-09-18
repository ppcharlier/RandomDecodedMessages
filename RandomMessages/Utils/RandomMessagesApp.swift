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
                if let digit = Int(String(a)), digit < charChart.count {
                    subchart = charChart[digit]
                } else {
                    subchart = ["?", "?", "?", "?", "?", "?", "?", "?", "?", "?"]
                }
            }

            if !chartSelect || index == message.count-1, let b = Int(String(a)) {
                if b < subchart.count {
                    message_trad += subchart[b]
                }
            }
            chartSelect = !chartSelect
        }
        return message_trad
    }
}


// MARK: - Data Models

// Modèle pour l'onglet "Oracle"
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

// NOUVEAUX MODÈLES POUR L'ONGLET "FLUX CONTINU"
struct DecodedSequenceData: Identifiable, Equatable {
    let id = UUID()
    let timestamp = Date()
    let numbers: [UInt64]
    let oracleSequence: String
    let oracleStartBit: Int
    let oracleByteLength: Int
    let chartAlignment: String
    let chartTargetLength: Int
    let chartDecodedMessage: String
}

enum FlowItem: Identifiable {
    case userThought(id: UUID, text: String)
    case decodedSequence(DecodedSequenceData)
    
    var id: UUID {
        switch self {
        case .userThought(let id, _):
            return id
        case .decodedSequence(let data):
            return data.id
        }
    }
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

// MARK: - Vues "Oracle" (inchangées)

struct DecodingDetailView: View {
    @Binding var result: DecodingResult
    var body: some View {
        List {
            Section(header: Text("Votre Requête")) { Text(result.userQuery.isEmpty ? "[Aucune requête spécifiée]" : result.userQuery).font(.headline).foregroundColor(result.userQuery.isEmpty ? .secondary : .primary).italic() }
            Section(header: Text("Évaluation de la Compréhension")) { HStack { Spacer(); StarRatingView(rating: $result.rating); Spacer() }.padding(.vertical) }
            Section(header: Text("Plus longue séquence UTF-8 lisible ('Réponse')")) {
                if result.longestUTF8Sequence.isEmpty { Text("Aucune séquence significative trouvée.").foregroundColor(.secondary) }
                else {
                    Text("\"\(result.longestUTF8Sequence)\"").font(.system(.title3, design: .serif).bold()).padding(.bottom, 4)
                    HStack { Image(systemName: "mappin.and.ellipse"); Text("Position de départ : bit N°\(result.longestUTF8StartBit)") }.font(.subheadline).foregroundColor(.secondary)
                    HStack { Image(systemName: "ruler"); Text("Longueur : \(result.longestUTF8ByteLength) octets") }.font(.subheadline).foregroundColor(.secondary)
                }
            }
            Section(header: Text("Décodage Linéaire (depuis le début)")) { Text(result.decodedUTF8).font(.system(.body, design: .default)) }
            Section(header: Text("Nombres Aléatoires (Hexadécimal)")) { Text(formatNumbers(result.numbers)).font(.system(.body, design: .monospaced)).contextMenu { Button(action: { UIPasteboard.general.string = formatNumbers(result.numbers) }) { Label("Copier", systemImage: "doc.on.doc") } } }
        }.listStyle(InsetGroupedListStyle()).navigationTitle(Text(result.timestamp, style: .time)).navigationBarTitleDisplayMode(.inline)
    }
    private func formatNumbers(_ numbers: [UInt64]) -> String { return numbers.map { String(format: "0x%016llX", $0) }.joined(separator: "\n") }
}

struct ContentView: View {
    @State private var history: [DecodingResult] = []
    @State private var isProcessing = false
    @State private var userQuery: String = ""
    private var dateFormatter: DateFormatter { let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    TextField("Écrivez une phrase ou une question ici...", text: $userQuery, axis: .vertical).padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3)
                    HStack { Button(action: generateAndDecode) { Label("Générer une Réponse", systemImage: "wand.and.stars").font(.headline) }.buttonStyle(.borderedProminent).tint(.blue).disabled(isProcessing); if isProcessing { ProgressView().padding(.leading, 10) } }
                }.padding().background(Color(.systemGroupedBackground))
                if history.isEmpty { VStack { Spacer(); Text("Aucun historique.").font(.title2).foregroundColor(.secondary); Text("Écrivez une phrase pour commencer.").foregroundColor(.secondary); Spacer() } }
                else { List { Section(header: Text("Historique des analyses")) { ForEach($history) { $result in NavigationLink(destination: DecodingDetailView(result: $result)) { historyRow(for: result) } }.onDelete(perform: deleteHistoryItem) } }.listStyle(InsetGroupedListStyle()) }
            }.navigationTitle("Oracle de Bits").toolbar { EditButton() }
        }
    }
    @ViewBuilder private func historyRow(for result: DecodingResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.timestamp, formatter: dateFormatter).font(.caption).foregroundColor(.secondary)
            Text(result.userQuery.isEmpty ? "[Requête vide]" : result.userQuery).font(.headline.italic()).lineLimit(2)
            HStack { Text(result.longestUTF8Sequence.isEmpty ? "[Aucune réponse]" : "Réponse : \"\(result.longestUTF8Sequence)\"").font(.system(.body, design: .monospaced)).lineLimit(2).foregroundColor(.primary); Spacer(); if result.rating > 0 { HStack(spacing: 2) { Text("\(result.rating)").bold(); Image(systemName: "star.fill") }.font(.caption).foregroundColor(.yellow) } }
        }.padding(.vertical, 6)
    }
    private func deleteHistoryItem(at offsets: IndexSet) { history.remove(atOffsets: offsets) }
    private func generateAndDecode() {
        isProcessing = true
        let queryForThisRun = userQuery
        DispatchQueue.global(qos: .userInitiated).async {
            let sequenceLength = Int.random(in: 8...15); let numbers = (0..<sequenceLength).map { _ in UInt64.random(in: .min ... .max) }; let utf8Result = decodeToUTF8(from: numbers); let longestSequenceResult = findLongestUTF8Sequence(from: numbers)
            DispatchQueue.main.async {
                let newResult = DecodingResult(timestamp: Date(), userQuery: queryForThisRun, numbers: numbers, decodedASCII: "", decodedUTF8: utf8Result, longestUTF8Sequence: longestSequenceResult.sequence, longestUTF8StartBit: longestSequenceResult.startBit, longestUTF8ByteLength: longestSequenceResult.byteLength); history.insert(newResult, at: 0); isProcessing = false; userQuery = ""
            }
        }
    }
    private func findLongestUTF8Sequence(from numbers: [UInt64]) -> (sequence: String, startBit: Int, byteLength: Int) {
        let buffer = BitBuffer(numbers: numbers); var overallBestSequence = ""; var overallBestStartBit = 0
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
    private func decodeToUTF8(from numbers: [UInt64]) -> String { var bitStream = BitStream(numbers: numbers); var byteArray: [UInt8] = []; while let byteValue = bitStream.read(bits: 8) { byteArray.append(UInt8(truncatingIfNeeded: byteValue)) }; return String(decoding: byteArray, as: UTF8.self) }
}

// MARK: - NOUVELLE VUE DE DÉTAIL POUR LE FLUX CONTINU

struct FlowDetailView: View {
    let sequenceData: DecodedSequenceData

    var body: some View {
        List {
            Section(header: Text("Analyse Oracle")) {
                if sequenceData.oracleSequence.isEmpty {
                    Text("Aucune séquence UTF-8 significative trouvée.").foregroundColor(.secondary)
                } else {
                    Text("\"\(sequenceData.oracleSequence)\"").font(.system(.title3, design: .serif).bold()).padding(.bottom, 4)
                    HStack { Image(systemName: "mappin.and.ellipse"); Text("Position de départ : bit N°\(sequenceData.oracleStartBit)") }.font(.subheadline).foregroundColor(.secondary)
                    HStack { Image(systemName: "ruler"); Text("Longueur : \(sequenceData.oracleByteLength) octets") }.font(.subheadline).foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Décodage 'Chart'")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Alignement:").bold()
                        Text(sequenceData.chartAlignment)
                    }
                    HStack {
                        Text("Longueur Cible:").bold()
                        Text("\(sequenceData.chartTargetLength)")
                    }
                    Divider()
                    Text("Message Normal:").bold().padding(.top, 4)
                    Text(sequenceData.chartDecodedMessage)
                    Text("Message Inversé:").bold().padding(.top, 8)
                    Text(String(sequenceData.chartDecodedMessage.reversed()))
                }
                .font(.system(.body, design: .monospaced))
            }

            Section(header: Text("Données Brutes (Hexadécimal)")) {
                Text(formatNumbers(sequenceData.numbers)).font(.system(.body, design: .monospaced))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text(sequenceData.timestamp, style: .time))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatNumbers(_ numbers: [UInt64]) -> String { return numbers.map { String(format: "0x%016llX", $0) }.joined(separator: "\n") }
}

// MARK: - VUE "FLUX CONTINU" (entièrement réarchitecturée)

struct ContinuousDecodingView: View {
    @State private var flowItems: [FlowItem] = []
    @State private var isDecoding = false
    @State private var decodingTask: Task<Void, Never>?
    @State private var userQuery: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private let generator = RandomMessagesGenerator()

    var body: some View {
        VStack(spacing: 0) {
            // --- Panneau de contrôle ---
            VStack(spacing: 12) {
                TextField("Formez vos pensées ici...", text: $userQuery, axis: .vertical).focused($isTextFieldFocused).padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3).tint(.orange)
                HStack {
                    if isTextFieldFocused { Label("Flux en pause", systemImage: "pause.circle.fill").font(.headline).foregroundColor(.orange) }
                    else { Text("Séquences Générées : \(flowItems.filter { if case .decodedSequence = $0 { return true } else { return false } }.count)").font(.headline) }
                    Spacer()
                }
            }.padding().background(Color(.systemGroupedBackground))

            // --- Liste des items ---
            List {
                ForEach(flowItems) { item in
                    switch item {
                    case .userThought(_, let text):
                        thoughtCell(text: text)
                    case .decodedSequence(let data):
                        NavigationLink(destination: FlowDetailView(sequenceData: data)) {
                            sequenceCell(data: data)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)

            // --- Bouton de contrôle ---
            Button(action: toggleDecoding) {
                Label(isDecoding ? "Arrêter le Flux" : "Démarrer le Flux", systemImage: isDecoding ? "stop.circle.fill" : "play.circle.fill").font(.title2.bold()).frame(maxWidth: .infinity)
            }.padding().background(isDecoding ? Color.red : Color.green).foregroundColor(.white).buttonStyle(.borderedProminent).tint(isDecoding ? .red : .green)
        }
        .navigationTitle("Flux Continu").navigationBarTitleDisplayMode(.inline)
        .onTapGesture { isTextFieldFocused = false }
        .onChange(of: isTextFieldFocused) { isFocused in
            if !isFocused && !userQuery.isEmpty {
                flowItems.append(.userThought(id: UUID(), text: userQuery)); userQuery = ""
            }
        }
    }
    
    // --- Vues pour les cellules de la liste ---
    @ViewBuilder private func thoughtCell(text: String) -> some View {
        HStack {
            Image(systemName: "bubble.left.fill").foregroundColor(.orange)
            Text(text).font(.body.italic())
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }

    @ViewBuilder private func sequenceCell(data: DecodedSequenceData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.timestamp, style: .time).font(.caption).foregroundColor(.secondary)
            Text(data.chartDecodedMessage).font(.system(.body, design: .monospaced))
            if !data.oracleSequence.isEmpty {
                Text("[Oracle] \"\(data.oracleSequence)\"").font(.caption).foregroundColor(.purple).lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    // --- Logique de génération ---
    private func toggleDecoding() { isDecoding.toggle(); if isDecoding { startDecoding() } else { stopDecoding() } }
    private func stopDecoding() { decodingTask?.cancel(); decodingTask = nil }

    private func startDecoding() {
        decodingTask = Task {
            while !Task.isCancelled {
                let isFocused = await MainActor.run { isTextFieldFocused }
                if isFocused { do { try await Task.sleep(nanoseconds: 500_000_000); continue } catch { break } }
                
                let numbers = (0..<Int.random(in: 2...4)).map { _ in UInt64.random(in: .min ... .max) }
                let longestSequenceResult = findLongestUTF8Sequence(from: numbers)
                let rawText = numbers.map { String($0) }.joined()
                guard rawText.count > 3 else { continue }

                let alignmentDigit = Int(String(rawText.prefix(1))) ?? 0
                let lengthDigits = Int(String(rawText.dropFirst().prefix(2))) ?? 0
                let messageDigits = String(rawText.dropFirst(3))
                
                let alignmentString = (alignmentDigit < 5) ? "GAUCHE" : "DROITE"
                let targetLength = (lengthDigits % 31) + 10
                var decodedChartMessage = generator.correspondancePerChart(message: messageDigits, charChart: generator.charChart)
                
                if decodedChartMessage.count > targetLength { decodedChartMessage = String(decodedChartMessage.prefix(targetLength)) }
                else { decodedChartMessage = decodedChartMessage.padding(toLength: targetLength, withPad: "·", startingAt: 0) }

                let sequenceData = DecodedSequenceData(
                    numbers: numbers,
                    oracleSequence: longestSequenceResult.sequence,
                    oracleStartBit: longestSequenceResult.startBit,
                    oracleByteLength: longestSequenceResult.byteLength,
                    chartAlignment: alignmentString,
                    chartTargetLength: targetLength,
                    chartDecodedMessage: decodedChartMessage
                )
                
                await MainActor.run { flowItems.append(.decodedSequence(sequenceData)) }
                do { try await Task.sleep(nanoseconds: 400_000_000) } catch { break }
            }
        }
    }
    
    private func findLongestUTF8Sequence(from numbers: [UInt64]) -> (sequence: String, startBit: Int, byteLength: Int) {
        let buffer = BitBuffer(numbers: numbers); var overallBestSequence = ""; var overallBestStartBit = 0
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
}


// MARK: - SwiftUI App Entry Point

@main
struct NumberDecoderApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Oracle", systemImage: "wand.and.stars") }
                
                NavigationView { ContinuousDecodingView() }
                    .tabItem { Label("Flux Continu", systemImage: "infinity.circle.fill") }
            }
        }
    }
}

