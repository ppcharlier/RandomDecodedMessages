import SwiftUI
import CoreData

// MARK: - Controller de Persistance CoreData
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RandomMessagesModel") // Assurez-vous d'avoir un modèle de données avec ce nom
        
        // Création manuelle du modèle de données car nous n'utilisons pas de fichier .xcdatamodeld
        let historyItemEntity = NSEntityDescription()
        historyItemEntity.name = "HistoryItem"
        historyItemEntity.managedObjectClassName = "HistoryItem"
        historyItemEntity.properties = [
            NSAttributeDescription(name: "id", type: .UUIDAttributeType),
            NSAttributeDescription(name: "timestamp", type: .dateAttributeType),
            NSAttributeDescription(name: "userQuery", type: .stringAttributeType),
            NSAttributeDescription(name: "numbers", type: .binaryDataAttributeType),
            NSAttributeDescription(name: "longestUTF8Sequence", type: .stringAttributeType),
            NSAttributeDescription(name: "oracleStartBit", type: .integer64AttributeType),
            NSAttributeDescription(name: "oracleByteLength", type: .integer64AttributeType),
            NSAttributeDescription(name: "rating", type: .integer64AttributeType)
        ]

        let chatItemEntity = NSEntityDescription()
        chatItemEntity.name = "ChatItem"
        chatItemEntity.managedObjectClassName = "ChatItem"
        
        let sequenceDataEntity = NSEntityDescription()
        sequenceDataEntity.name = "SequenceData"
        sequenceDataEntity.managedObjectClassName = "SequenceData"
        sequenceDataEntity.properties = [
            NSAttributeDescription(name: "id", type: .UUIDAttributeType),
            NSAttributeDescription(name: "numbers", type: .binaryDataAttributeType),
            NSAttributeDescription(name: "oracleSequence", type: .stringAttributeType),
            NSAttributeDescription(name: "oracleStartBit", type: .integer64AttributeType),
            NSAttributeDescription(name: "oracleByteLength", type: .integer64AttributeType),
            NSAttributeDescription(name: "chartAlignment", type: .stringAttributeType),
            NSAttributeDescription(name: "chartTargetLength", type: .integer64AttributeType),
            NSAttributeDescription(name: "chartDecodedMessage", type: .stringAttributeType)
        ]
        
        let sequenceRelationship = NSRelationshipDescription()
        sequenceRelationship.name = "sequence"
        sequenceRelationship.destinationEntity = sequenceDataEntity
        sequenceRelationship.minCount = 0
        sequenceRelationship.maxCount = 1
        sequenceRelationship.deleteRule = .cascadeDeleteRule
        
        let chatItemRelationship = NSRelationshipDescription()
        chatItemRelationship.name = "chatItem"
        chatItemRelationship.destinationEntity = chatItemEntity
        chatItemRelationship.minCount = 0
        chatItemRelationship.maxCount = 1
        chatItemRelationship.deleteRule = .nullifyDeleteRule
        
        sequenceRelationship.inverseRelationship = chatItemRelationship
        chatItemRelationship.inverseRelationship = sequenceRelationship
        
        chatItemEntity.properties = [
            NSAttributeDescription(name: "id", type: .UUIDAttributeType),
            NSAttributeDescription(name: "timestamp", type: .dateAttributeType),
            NSAttributeDescription(name: "type", type: .stringAttributeType),
            NSAttributeDescription(name: "thoughtText", type: .stringAttributeType, isOptional: true),
            sequenceRelationship
        ]
        
        sequenceDataEntity.properties.append(chatItemRelationship)

        let model = NSManagedObjectModel()
        model.entities = [historyItemEntity, chatItemEntity, sequenceDataEntity]
        container.persistentStoreDescriptions.first!.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions.first!.shouldInferMappingModelAutomatically = true
        container.managedObjectModel = model

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// Classes de Managed Object
public class HistoryItem: NSManagedObject {}
public class ChatItem: NSManagedObject {}
public class SequenceData: NSManagedObject {}


// MARK: - Votre code intégré
class RandomMessagesGenerator {
    let charVersion: String = "0.1"
    var charChart = [[ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], [ "A", "B", "C", "D", "E", "F", "G", "H", "I", "J"], [ "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"], [ "U", "V", "W", "X", "Y", "Z", "a", "b" ,"c", "d"], [ "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"], [ "o", "p", "q", "r", "s", "t", "u", "v", "w", "x"], [ "y", "z", "?", ",", ".", ";", "/", ":", "+", "="], [ "-", "*", "/", "(", ")", "{", "}", "<", ">", "["], [ "]", " ", "\\", "#", "@", "&", " ", " ", "^", "¨"], [  "%", "£", "€", "°", "\'", "\"", "_", "\t", "\n", "~"]]
    func retrieveText() -> String { var m = ""; var a: String; var i = Int.random(in: 1...3); repeat { arc4random_stir(); a = String(arc4random()); m += a; i -= 1 } while i > 0; return "\(m)" }
    func correspondancePerChart(message: String, charChart: [[String]]) -> String { var cs = true; var mt = ""; var sc: [String] = charChart[9]; for (index, a) in message.enumerated() { if cs || index == message.count-1 { if let d = Int(String(a)), d < charChart.count { sc = charChart[d] } else { sc = ["?","?","?","?","?","?","?","?","?","?"] } }; if !cs || index == message.count-1, let b = Int(String(a)) { if b < sc.count { mt += sc[b] } }; cs = !cs }; return mt }
}


// MARK: - Data Models (Structs for temporary use)
struct DecodedSequenceData {
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

// MARK: - Bit Helpers
struct BitStream { private let n: [UInt64]; private var i=0; private var b=0; init(numbers: [UInt64]){self.n=numbers}; mutating func read(bits c: Int)->UInt64?{ guard c>0,c<=64 else{return nil}; let t=(n.count-i)*64-b; guard t>=c else{return nil}; var r:UInt64=0; var d=0; while d<c{guard i<n.count else{break}; let cn=n[i]; let R=64-b; let N=min(c-d,R); let m:UInt64=(N==64) ?.max :(1<<N)-1; let e=(cn>>b)&m; r|=(e<<d); d+=N; b+=N; if b==64{b=0;i+=1}}; return r }}
struct BitBuffer { let n:[UInt64]; let t:Int; init(numbers:[UInt64]){self.n=numbers;self.t=numbers.count*64}; func read(bits c:Int,from o:Int)->UInt64?{ guard c>0,c<=64,o>=0,(o+c)<=t else{return nil}; var r:UInt64=0; var d=0; var ci=o/64; var bi=o%64; while d<c{ guard ci<n.count else{break}; let cn=n[ci]; let R=64-bi; let N=min(c-d,R); let m:UInt64=(N==64) ?.max :(1<<N)-1; let e=(cn>>bi)&m; r|=(e<<d); d+=N; bi+=N; if bi==64{bi=0;ci+=1}}; return r }}

// MARK: - Reusable UI Components
struct StarRatingView: View { @Binding var rating:Int; var body: some View { HStack { ForEach(1...5,id:\.self){n in Image(systemName:n>rating ?"star":"star.fill").resizable().scaledToFit().foregroundColor(.yellow).frame(width:30,height:30).onTapGesture{rating=(n==rating) ?0:n}}}}}

// MARK: - Vues "Oracle"
struct DecodingDetailView: View {
    @ObservedObject var result: HistoryItem
    var body: some View {
        List {
            Section(header: Text("Votre Requête")) { Text(result.userQuery ?? "[Aucune requête spécifiée]").font(.headline).foregroundColor((result.userQuery ?? "").isEmpty ? .secondary : .primary).italic() }
            Section(header: Text("Évaluation")) { HStack{Spacer(); StarRatingView(rating: .init(get: { Int(result.rating) }, set: { result.rating = Int64($0); try? result.managedObjectContext?.save() })); Spacer()}.padding(.vertical) }
            Section(header: Text("Réponse Oracle")) {
                if (result.longestUTF8Sequence ?? "").isEmpty { Text("Aucune séquence trouvée.").foregroundColor(.secondary) }
                else { Text("\"\(result.longestUTF8Sequence!)\"").font(.system(.title3,design:.serif).bold()).padding(.bottom,4); HStack{Image(systemName:"mappin.and.ellipse"); Text("Départ: bit N°\(result.oracleStartBit)")}.font(.subheadline).foregroundColor(.secondary); HStack{Image(systemName:"ruler"); Text("Longueur: \(result.oracleByteLength) octets")}.font(.subheadline).foregroundColor(.secondary) }
            }
            Section(header: Text("Données Brutes (Hex)")) { Text(formatNumbers(result.numbers)).font(.system(.body,design:.monospaced)).contextMenu{Button(action:{UIPasteboard.general.string=formatNumbers(result.numbers)}){Label("Copier",systemImage:"doc.on.doc")}}}
        }
        .listStyle(InsetGroupedListStyle()).navigationTitle(Text(result.timestamp ?? Date(), style: .time)).navigationBarTitleDisplayMode(.inline)
    }
    private func formatNumbers(_ data: Data?) -> String { guard let data = data, let numbers = try? JSONDecoder().decode([UInt64].self, from: data) else { return "" }; return numbers.map {String(format:"0x%016llX",$0)}.joined(separator:"\n") }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \HistoryItem.timestamp, ascending: false)], animation: .default)
    private var history: FetchedResults<HistoryItem>
    
    @State private var isProcessing = false
    @State private var userQuery: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing:12){TextField("Écrivez une phrase...",text:$userQuery,axis:.vertical).padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3); HStack{Button(action:generateAndDecode){Label("Générer une Réponse",systemImage:"wand.and.stars").font(.headline)}.buttonStyle(.borderedProminent).tint(.blue).disabled(isProcessing); if isProcessing{ProgressView().padding(.leading,10)}}}.padding().background(Color(.systemGroupedBackground))
                if history.isEmpty { VStack{Spacer(); Text("Aucun historique.").font(.title2).foregroundColor(.secondary); Text("Écrivez une phrase pour commencer.").foregroundColor(.secondary); Spacer()}}
                else { List{ForEach(history){result in NavigationLink(destination:DecodingDetailView(result:result)){historyRow(for:result)}}.onDelete(perform:deleteHistoryItems)}.listStyle(InsetGroupedListStyle())}
            }.navigationTitle("Oracle de Bits")
        }
    }
    @ViewBuilder private func historyRow(for result:HistoryItem) -> some View { let dateFmt:DateFormatter={let f=DateFormatter();f.dateStyle = .short;f.timeStyle = .short;return f}(); VStack(alignment:.leading,spacing:8){Text(result.timestamp ?? Date(),formatter:dateFmt).font(.caption).foregroundColor(.secondary); Text(result.userQuery ?? "[Requête vide]").font(.headline.italic()).lineLimit(2); HStack{Text((result.longestUTF8Sequence ?? "").isEmpty ? "[Aucune réponse]" : "Réponse: \"\(result.longestUTF8Sequence!)\"").font(.system(.body,design:.monospaced)).lineLimit(2).foregroundColor(.primary); Spacer(); if result.rating>0{HStack(spacing:2){Text("\(result.rating)").bold(); Image(systemName:"star.fill")}.font(.caption).foregroundColor(.yellow)}}}.padding(.vertical,6) }
    private func deleteHistoryItems(offsets:IndexSet){withAnimation{offsets.map{history[$0]}.forEach(viewContext.delete); try? viewContext.save()}}
    private func generateAndDecode() {
        isProcessing = true
        let queryForThisRun = userQuery
        DispatchQueue.global(qos:.userInitiated).async {
            let nums=(0..<Int.random(in:8...15)).map{_ in UInt64.random(in:.min ... .max)}; let longestSeq=findLongestUTF8Sequence(from:nums); let numsData=try? JSONEncoder().encode(nums)
            DispatchQueue.main.async {
                let newItem=HistoryItem(context:viewContext); newItem.id=UUID(); newItem.timestamp=Date(); newItem.userQuery=queryForThisRun; newItem.numbers=numsData; newItem.longestUTF8Sequence=longestSeq.sequence; newItem.oracleStartBit=Int64(longestSeq.startBit); newItem.oracleByteLength=Int64(longestSeq.byteLength); newItem.rating=0
                try? viewContext.save(); isProcessing=false; userQuery=""
            }
        }
    }
    private func findLongestUTF8Sequence(from nums:[UInt64])->(sequence:String,startBit:Int,byteLength:Int){let buf=BitBuffer(numbers:nums);var bestS="";var bestB=0;for sB in 0..<(buf.t-7){var curB:[UInt8]=[];var lS="";for bI in 0...{let cO=sB+(bI*8);guard let bV=buf.read(bits:8,from:cO)else{break};curB.append(UInt8(truncatingIfNeeded:bV));let tS=String(decoding:curB,as:UTF8.self);if !tS.contains("\u{FFFD}"){lS=tS}else{break}};if lS.count>bestS.count{bestS=lS;bestB=sB}};return(bestS,bestB,bestS.utf8.count)}
}

// MARK: - Vues "Flux Continu"
struct FlowDetailView: View {
    let sequenceData: SequenceData
    var body: some View {
        List {
            Section(header:Text("Analyse Oracle")){if (sequenceData.oracleSequence ?? "").isEmpty{Text("Aucune séquence UTF-8 trouvée.").foregroundColor(.secondary)}else{Text("\"\(sequenceData.oracleSequence!)\"").font(.system(.title3,design:.serif).bold()).padding(.bottom,4); HStack{Image(systemName:"mappin.and.ellipse");Text("Départ: bit N°\(sequenceData.oracleStartBit)")}.font(.subheadline).foregroundColor(.secondary); HStack{Image(systemName:"ruler");Text("Longueur: \(sequenceData.oracleByteLength) octets")}.font(.subheadline).foregroundColor(.secondary)}}
            Section(header:Text("Décodage 'Chart'")){VStack(alignment:.leading,spacing:8){HStack{Text("Alignement:").bold();Text(sequenceData.chartAlignment ?? "")};HStack{Text("Longueur Cible:").bold();Text("\(sequenceData.chartTargetLength)")};Divider();Text("Message Normal:").bold().padding(.top,4);Text(sequenceData.chartDecodedMessage ?? "");Text("Message Inversé:").bold().padding(.top,8);Text(String((sequenceData.chartDecodedMessage ?? "").reversed()))}.font(.system(.body,design:.monospaced))}
            Section(header:Text("Données Brutes (Hex)")) {Text(formatNumbers(sequenceData.numbers)).font(.system(.body,design:.monospaced))}
        }.listStyle(InsetGroupedListStyle()).navigationTitle(Text(Date(), style:.time)).navigationBarTitleDisplayMode(.inline) // Date() is a placeholder, timestamp is not on SequenceData
    }
    private func formatNumbers(_ data:Data?)->String{guard let d=data,let n=try? JSONDecoder().decode([UInt64].self,from:d)else{return ""};return n.map{String(format:"0x%016llX",$0)}.joined(separator:"\n")}
}

struct ContinuousDecodingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChatItem.timestamp, ascending: true)], animation: .default)
    private var flowItems: FetchedResults<ChatItem>
    
    @State private var isDecoding = false; @State private var decodingTask: Task<Void, Never>?; @State private var userQuery: String = ""; @FocusState private var isTextFieldFocused: Bool
    private let generator = RandomMessagesGenerator()

    var body: some View {
        VStack(spacing:0){
            VStack(spacing:12){TextField("Formez vos pensées...",text:$userQuery,axis:.vertical).focused($isTextFieldFocused).padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3).tint(.orange); HStack{if isTextFieldFocused{Label("Flux en pause",systemImage:"pause.circle.fill").font(.headline).foregroundColor(.orange)}else{Text("Séquences: \(flowItems.filter{$0.type == "sequence"}.count)").font(.headline)}; Spacer()}}.padding().background(Color(.systemGroupedBackground))
            List{ForEach(flowItems){item in if item.type=="thought"{thoughtCell(text:item.thoughtText ?? "")}else if let seqData=item.sequence{NavigationLink(destination:FlowDetailView(sequenceData:seqData)){sequenceCell(data:seqData)}}}.listRowSeparator(.hidden).listRowInsets(EdgeInsets(top:8,leading:16,bottom:8,trailing:16))}.listStyle(.plain)
            Button(action:toggleDecoding){Label(isDecoding ?"Arrêter":"Démarrer",systemImage:isDecoding ?"stop.circle.fill":"play.circle.fill").font(.title2.bold()).frame(maxWidth:.infinity)}.padding().background(isDecoding ?.red:.green).foregroundColor(.white).buttonStyle(.borderedProminent).tint(isDecoding ?.red:.green)
        }.navigationTitle("Flux Continu").navigationBarTitleDisplayMode(.inline).onTapGesture{isTextFieldFocused=false}.onChange(of:isTextFieldFocused){isFocused in if !isFocused, !userQuery.isEmpty{addThought(text:userQuery);userQuery=""}}
    }
    @ViewBuilder private func thoughtCell(text:String)->some View{HStack{Image(systemName:"bubble.left.fill").foregroundColor(.orange); Text(text).font(.body.italic()); Spacer()}.padding().background(Color.orange.opacity(0.1)).cornerRadius(10)}
    @ViewBuilder private func sequenceCell(data:SequenceData)->some View{VStack(alignment:.leading,spacing:8){Text(Date(), style:.time).font(.caption).foregroundColor(.secondary); Text(data.chartDecodedMessage ?? "").font(.system(.body,design:.monospaced)); if !(data.oracleSequence ?? "").isEmpty{Text("[Oracle] \"\(data.oracleSequence!)\"").font(.caption).foregroundColor(.purple).lineLimit(1)}}.padding(.vertical,4)}
    private func addThought(text: String) { let newItem = ChatItem(context: viewContext); newItem.id = UUID(); newItem.timestamp = Date(); newItem.type = "thought"; newItem.thoughtText = text; try? viewContext.save() }
    private func toggleDecoding(){isDecoding.toggle();if isDecoding{startDecoding()}else{stopDecoding()}}
    private func stopDecoding(){decodingTask?.cancel();decodingTask=nil}
    private func startDecoding() {
        decodingTask = Task {
            while !Task.isCancelled {
                if await MainActor.run(where:{isTextFieldFocused}){do{try await Task.sleep(nanoseconds:500_000_000);continue}catch{break}}
                let nums=(0..<Int.random(in:2...4)).map{_ in UInt64.random(in:.min ... .max)}; let lS=findLongestUTF8Sequence(from:nums); let rT=nums.map{String($0)}.joined(); guard rT.count>3 else{continue}; let aD=Int(String(rT.prefix(1)))??0; let lD=Int(String(rT.dropFirst().prefix(2)))??0; let mD=String(rT.dropFirst(3)); let aS=(aD<5) ?"GAUCHE":"DROITE"; let tL=(lD%31)+10; var dM=generator.correspondancePerChart(message:mD,charChart:generator.charChart); if dM.count>tL{dM=String(dM.prefix(tL))}else{dM=dM.padding(toLength:tL,withPad:"·",startingAt:0)}
                let numsData = try? JSONEncoder().encode(nums)
                
                await MainActor.run {
                    let newItem = ChatItem(context: viewContext); newItem.id = UUID(); newItem.timestamp = Date(); newItem.type = "sequence"
                    let seqData = SequenceData(context: viewContext); seqData.id = UUID(); seqData.numbers = numsData; seqData.oracleSequence = lS.sequence; seqData.oracleStartBit = Int64(lS.startBit); seqData.oracleByteLength = Int64(lS.byteLength); seqData.chartAlignment = aS; seqData.chartTargetLength = Int64(tL); seqData.chartDecodedMessage = dM
                    newItem.sequence = seqData
                    try? viewContext.save()
                }
                do{try await Task.sleep(nanoseconds:400_000_000)}catch{break}
            }
        }
    }
    private func findLongestUTF8Sequence(from nums:[UInt64])->(sequence:String,startBit:Int,byteLength:Int){let buf=BitBuffer(numbers:nums);var bestS="";var bestB=0;for sB in 0..<(buf.t-7){var cB:[UInt8]=[];var lS="";for bI in 0...{let cO=sB+(bI*8);guard let bV=buf.read(bits:8,from:cO)else{break};cB.append(UInt8(truncatingIfNeeded:bV));let tS=String(decoding:cB,as:UTF8.self);if !tS.contains("\u{FFFD}"){lS=tS}else{break}};if lS.count>bestS.count{bestS=lS;bestB=sB}};return(bestS,bestB,bestS.utf8.count)}
}

// MARK: - SwiftUI App Entry Point
@main
struct NumberDecoderApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Oracle", systemImage: "wand.and.stars") }
                NavigationView { ContinuousDecodingView() }
                    .tabItem { Label("Flux Continu", systemImage: "infinity.circle.fill") }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

