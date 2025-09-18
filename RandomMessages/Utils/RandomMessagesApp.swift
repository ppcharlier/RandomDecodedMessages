import SwiftUI
import CoreData

// MARK: - INSTRUCTIONS POUR CHANGER DE MODE (AVEC OU SANS CORE DATA)
//
// Pour activer/désactiver la persistance des données avec Core Data, suivez ces étapes :
//
// 1. Dans Xcode, cliquez sur le nom de votre projet dans le navigateur de fichiers (tout en haut à gauche).
// 2. Assurez-vous que votre projet est sélectionné dans la section "PROJECT", puis cliquez sur l'onglet "Build Settings".
// 3. Dans la barre de recherche des "Build Settings", tapez : Active Compilation Conditions
// 4. Vous verrez une ligne pour "Debug" et "Release". Double-cliquez sur la colonne à droite de "Debug".
// 5. Pour ACTIVER Core Data : Ajoutez `USE_CORE_DATA` sur une nouvelle ligne.
// 6. Pour DÉSACTIVER Core Data : Supprimez la ligne `USE_CORE_DATA`.
//
// Vous devez ensuite recompiler l'application pour que le changement prenne effet.

#if USE_CORE_DATA
// MARK: - Core Data Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RandomMessagesModel")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}


// MARK: - CoreData Managed Object Classes
public class HistoryItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var userQuery: String?
    @NSManaged public var numbers: Data?
    @NSManaged public var longestUTF8Sequence: String?
    @NSManaged public var oracleStartBit: Int64
    @NSManaged public var oracleByteLength: Int64
    @NSManaged public var rating: Int64
}

public class ChatItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var type: String? // "thought" or "sequence"
    @NSManaged public var thoughtText: String?
    @NSManaged public var sequence: SequenceData?
}

public class SequenceData: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var numbers: Data?
    @NSManaged public var oracleSequence: String?
    @NSManaged public var oracleStartBit: Int64
    @NSManaged public var oracleByteLength: Int64
    @NSManaged public var chartAlignment: String?
    @NSManaged public var chartTargetLength: Int64
    @NSManaged public var chartDecodedMessage: String?
    @NSManaged public var chatItem: ChatItem?
}
#else
// MARK: - Modèles de Données en Mémoire (Sans Core Data)
struct DecodingResult: Identifiable {
    let id = UUID()
    var timestamp: Date
    var userQuery: String
    var numbers: [UInt64]
    var longestUTF8Sequence: String
    var oracleStartBit: Int
    var oracleByteLength: Int
    var rating: Int = 0
}

struct DecodedSequenceData: Identifiable {
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
        case .userThought(let id, _): return id
        case .decodedSequence(let data): return data.id
        }
    }
}
#endif


// MARK: - Random Messages Generator
class RandomMessagesGenerator {
    let charChart = [["0","1","2","3","4","5","6","7","8","9"],["A","B","C","D","E","F","G","H","I","J"],["K","L","M","N","O","P","Q","R","S","T"],["U","V","W","X","Y","Z","a","b","c","d"],["e","f","g","h","i","j","k","l","m","n"],["o","p","q","r","s","t","u","v","w","x"],["y","z","? ",",",".",";","/ ",":","+","="],["-","*","/ ","(",")","{","}","<",">","["],["]"," ","\\","#","@","&"," "," ","^","¨"],["%","£","€","°","'","\"","_","\t","\n","~"]]
    func correspondancePerChart(message: String) -> String { var cs=true; var mt=""; var sc=charChart[9]; for(i,a) in message.enumerated(){if cs||i==message.count-1{if let d=Int(String(a)),d<charChart.count{sc=charChart[d]}else{sc=["?","?","?","?","?","?","?","?","?","?"]}};if !cs||i==message.count-1,let b=Int(String(a)){if b<sc.count{mt+=sc[b]}};cs = !cs};return mt}
}

// MARK: - Bit Helpers
struct BitBuffer{let n:[UInt64];let t:Int;init(n:[UInt64]){self.n=n;self.t=n.count*64};func read(bits c:Int,from o:Int)->UInt64?{guard c>0,c<=64,o>=0,(o+c)<=t else{return nil};var r:UInt64=0;var d=0;var ci=o/64;var bi=o%64;while d<c{guard ci<n.count else{break};let cN=n[ci];let rI=64-bi;let nTR=min(c-d,rI);let m:UInt64=(nTR==64) ?.max :(1<<nTR)-1;let e=(cN>>bi)&m;r|=(e<<d);d+=nTR;bi+=nTR;if bi==64{bi=0;ci+=1}};return r}}
func findLongestUTF8Sequence(from nums:[UInt64])->(seq:String,bit:Int,len:Int){let b=BitBuffer(n:nums);var oS="";var oB=0;for sB in 0..<(b.t-7){var cB:[UInt8]=[];var lS="";var bI=0;while true{let cO=sB+(bI*8);guard let bV=b.read(bits:8,from:cO)else{break};cB.append(UInt8(truncatingIfNeeded:bV));let tS=String(decoding:cB,as:UTF8.self);if !tS.contains("\u{FFFD}"){lS=tS}else{break};bI+=1};if lS.count>oS.count{oS=lS;oB=sB}};return(oS,oB,oS.utf8.count)}
func formatNumbers(_ data:Data?)->String{guard let d=data,let n=try? JSONDecoder().decode([UInt64].self,from:d)else{return ""};return n.map{String(format:"0x%016llX",$0)}.joined(separator:"\n")}
func formatNumbers(_ nums:[UInt64])->String{return nums.map{String(format:"0x%016llX",$0)}.joined(separator:"\n")}


// MARK: - Reusable UI Components
struct StarRatingView: View{ @Binding var rating: Int; var body: some View{ HStack{ ForEach(1...5,id:\.self){n in Image(systemName:n>rating ?"star":"star.fill").resizable().scaledToFit().foregroundColor(.yellow).frame(width:30,height:30).onTapGesture{rating=(n==rating) ?0:n}}}}}

// MARK: - Vues "Oracle"
struct DecodingDetailView: View {
    #if USE_CORE_DATA
    @ObservedObject var result: HistoryItem
    #else
    @Binding var result: DecodingResult
    #endif

    var body: some View {
        List {
            Section(header:Text("Votre Requête")){Text(result.userQuery ?? "[Aucune]").font(.headline).italic()}
            
            #if USE_CORE_DATA
            Section(header:Text("Évaluation")){HStack{Spacer();StarRatingView(rating:.init(get:{Int(result.rating)},set:{result.rating=Int64($0);try? result.managedObjectContext?.save()}));Spacer()}.padding(.vertical)}
            #else
            Section(header:Text("Évaluation")){HStack{Spacer();StarRatingView(rating: $result.rating);Spacer()}.padding(.vertical)}
            #endif
            
            Section(header:Text("Réponse Oracle")){
                if (result.longestUTF8Sequence ?? "").isEmpty {
                    Text("Aucune séquence trouvée.").foregroundColor(.secondary)
                } else {
                    Text("\"\(result.longestUTF8Sequence)\"").font(.system(.title3,design:.serif).bold()).padding(.bottom,4)
                    HStack{Image(systemName:"mappin.and.ellipse");Text("Départ: bit N°\(result.oracleStartBit)")}.font(.subheadline)
                    HStack{Image(systemName:"ruler");Text("Longueur: \(result.oracleByteLength) octets")}.font(.subheadline)
                }
            }
            
            #if USE_CORE_DATA
            Section(header:Text("Données Brutes (Hex)")){Text(formatNumbers(result.numbers)).font(.system(.body,design:.monospaced)).contextMenu{Button(action:{UIPasteboard.general.string=formatNumbers(result.numbers)}){Label("Copier",systemImage:"doc.on.doc")}}}
            #else
            Section(header:Text("Données Brutes (Hex)")){Text(formatNumbers(result.numbers)).font(.system(.body,design:.monospaced)).contextMenu{Button(action:{UIPasteboard.general.string=formatNumbers(result.numbers)}){Label("Copier",systemImage:"doc.on.doc")}}}
            #endif
            
        }.listStyle(InsetGroupedListStyle()).navigationTitle(Text(result.timestamp, style: .time)).navigationBarTitleDisplayMode(.inline)
    }
}

struct ContentView: View {
    #if USE_CORE_DATA
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors:[NSSortDescriptor(keyPath:\HistoryItem.timestamp,ascending:false)],animation:.default) private var history: FetchedResults<HistoryItem>
    #else
    @State private var history: [DecodingResult] = []
    #endif

    @State private var isProcessing = false
    @State private var userQuery: String = ""

    var body: some View {
        NavigationView{VStack(spacing:0){VStack(spacing:12){TextField("Écrivez une phrase...",text:$userQuery,axis:.vertical).padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3);HStack{Button(action:generateAndDecode){Label("Générer",systemImage:"wand.and.stars")}.buttonStyle(.borderedProminent).tint(.blue).disabled(isProcessing);if isProcessing{ProgressView().padding(.leading,10)}}}.padding().background(Color(.systemGroupedBackground));if history.isEmpty{VStack{Spacer();Text("Aucun historique.").font(.title2).foregroundColor(.secondary);Spacer()}}else{
            #if USE_CORE_DATA
            List{ForEach(history){r in NavigationLink(destination:DecodingDetailView(result:r)){historyRow(for:r)}}.onDelete(perform:deleteItems)}.listStyle(InsetGroupedListStyle())
            #else
            List{ForEach($history){$r in NavigationLink(destination:DecodingDetailView(result:$r)){historyRow(for:r)}}.onDelete(perform:deleteItems)}.listStyle(InsetGroupedListStyle())
            #endif
        }}.navigationTitle("Oracle de Bits")}
    }
    
    #if USE_CORE_DATA
    @ViewBuilder private func historyRow(for r:HistoryItem)->some View{VStack(alignment:.leading,spacing:8){Text(r.timestamp,style:.time).font(.caption).foregroundColor(.secondary);Text(r.userQuery ?? "[Requête vide]").font(.headline.italic()).lineLimit(2);HStack{Text((r.longestUTF8Sequence ?? "").isEmpty ?"[Aucune réponse]":"Réponse: \"\(r.longestUTF8Sequence!)\"").font(.system(.body,design:.monospaced)).lineLimit(2);Spacer();if r.rating>0{HStack(spacing:2){Text("\(r.rating)").bold();Image(systemName:"star.fill")}.font(.caption).foregroundColor(.yellow)}}}.padding(.vertical,6)}
    #else
    @ViewBuilder private func historyRow(for r:DecodingResult)->some View{VStack(alignment:.leading,spacing:8){Text(r.timestamp,style:.time).font(.caption).foregroundColor(.secondary);Text(r.userQuery).font(.headline.italic()).lineLimit(2);HStack{Text(r.longestUTF8Sequence.isEmpty ?"[Aucune réponse]":"Réponse: \"\(r.longestUTF8Sequence)\"").font(.system(.body,design:.monospaced)).lineLimit(2);Spacer();if r.rating>0{HStack(spacing:2){Text("\(r.rating)").bold();Image(systemName:"star.fill")}.font(.caption).foregroundColor(.yellow)}}}.padding(.vertical,6)}
    #endif
    
    private func deleteItems(offsets:IndexSet){
        withAnimation {
            #if USE_CORE_DATA
            offsets.map{history[$0]}.forEach(viewContext.delete)
            #else
            history.remove(atOffsets: offsets)
            #endif
            saveContext()
        }
    }
    
    private func generateAndDecode(){
        isProcessing=true
        let q=userQuery
        DispatchQueue.global(qos:.userInitiated).async{
            let n=(0..<Int.random(in:8...15)).map{_ in UInt64.random(in:.min ... .max)}
            let lS=findLongestUTF8Sequence(from:n)
            
            DispatchQueue.main.async{
                #if USE_CORE_DATA
                let nD=try? JSONEncoder().encode(n)
                let i=HistoryItem(context:viewContext);i.id=UUID();i.timestamp=Date();i.userQuery=q;i.numbers=nD;i.longestUTF8Sequence=lS.seq;i.oracleStartBit=Int64(lS.bit);i.oracleByteLength=Int64(lS.len);i.rating=0;
                #else
                let result = DecodingResult(timestamp: Date(), userQuery: q, numbers: n, longestUTF8Sequence: lS.seq, oracleStartBit: lS.bit, oracleByteLength: lS.len, rating: 0)
                history.insert(result, at: 0)
                #endif
                
                saveContext()
                isProcessing=false
                userQuery=""
            }
        }
    }
    
    private func saveContext(){
        #if USE_CORE_DATA
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        #endif
    }
}

// MARK: - Vues "Flux Continu"
struct FlowDetailView: View {
    #if USE_CORE_DATA
    @ObservedObject var sequenceData: SequenceData
    #else
    let sequenceData: DecodedSequenceData
    #endif

    var body: some View {
        List {
            Section(header:Text("Analyse Oracle")){if(sequenceData.oracleSequence ?? "").isEmpty{Text("Aucune séquence trouvée.").foregroundColor(.secondary)}else{Text("\"\(sequenceData.oracleSequence)\"").font(.system(.title3,design:.serif).bold()).padding(.bottom,4);HStack{Image(systemName:"mappin.and.ellipse");Text("Départ: bit N°\(sequenceData.oracleStartBit)")}.font(.subheadline);HStack{Image(systemName:"ruler");Text("Longueur: \(sequenceData.oracleByteLength) octets")}.font(.subheadline)}}
            Section(header:Text("Décodage 'Chart'")){VStack(alignment:.leading,spacing:8){HStack{Text("Alignement:").bold();Text(sequenceData.chartAlignment ?? "N/A")};HStack{Text("Longueur Cible:").bold();Text("\(sequenceData.chartTargetLength)")};Divider();Text("Message Normal:").bold().padding(.top,4);Text(sequenceData.chartDecodedMessage ?? "");Text("Message Inversé:").bold().padding(.top,8);Text(String((sequenceData.chartDecodedMessage ?? "").reversed()))}.font(.system(.body,design:.monospaced))}
            
            #if USE_CORE_DATA
            Section(header:Text("Données Brutes (Hex)")) {Text(formatNumbers(sequenceData.numbers)).font(.system(.body,design:.monospaced))}
            #else
            Section(header:Text("Données Brutes (Hex)")) {Text(formatNumbers(sequenceData.numbers)).font(.system(.body,design:.monospaced))}
            #endif
        }.listStyle(InsetGroupedListStyle()).navigationTitle(Text(sequenceData.timestamp, style:.time)).navigationBarTitleDisplayMode(.inline)
    }
}

struct ContinuousDecodingView: View {
    #if USE_CORE_DATA
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors:[NSSortDescriptor(keyPath:\ChatItem.timestamp,ascending:true)],animation:.default) private var flowItems: FetchedResults<ChatItem>
    #else
    @State private var flowItems: [FlowItem] = []
    #endif

    @State private var isDecoding=false;@State private var decodingTask:Task<Void,Never>?;@State private var userQuery="";@FocusState private var isTextFieldFocused:Bool
    private let generator = RandomMessagesGenerator()
    private let bottomID = "bottom-anchor"

    var body: some View {
        VStack(spacing:0){
            VStack(spacing:12){TextField("Formez vos pensées...",text:$userQuery,axis:.vertical).focused($isTextFieldFocused).padding(10).background(Color(.secondarySystemBackground)).cornerRadius(10).lineLimit(1...3).tint(.orange);HStack{if isTextFieldFocused{Label("Flux en pause",systemImage:"pause.circle.fill").font(.headline).foregroundColor(.orange)}else{
                #if USE_CORE_DATA
                Text("Séquences: \(flowItems.filter{$0.type=="sequence"}.count)").font(.headline)
                #else
                Text("Séquences: \(flowItems.filter{if case .decodedSequence = $0 {return true} else {return false}}.count)").font(.headline)
                #endif
            };Spacer()}}.padding().background(Color(.systemGroupedBackground))
            
            // MODIFICATION ICI: Ajout du ScrollViewReader et de l'ancre
            ScrollViewReader { proxy in
                List {
                    #if USE_CORE_DATA
                    ForEach(flowItems) { item in
                        if item.type == "thought" {
                            thoughtCell(text: item.thoughtText ?? "")
                        } else if let seqData = item.sequence {
                            NavigationLink(destination: FlowDetailView(sequenceData: seqData)) {
                                sequenceCell(data: seqData)
                            }
                        }
                    }.onDelete(perform:deleteItems)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top:8,leading:16,bottom:8,trailing:16))
                    #else
                    ForEach(flowItems) { item in
                        switch item {
                        case .userThought(_, let text):
                            thoughtCell(text: text)
                        case .decodedSequence(let data):
                            NavigationLink(destination: FlowDetailView(sequenceData: data)) {
                                sequenceCell(data: data)
                            }
                        }
                    }.onDelete(perform:deleteItems)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top:8,leading:16,bottom:8,trailing:16))
                    #endif
                    

                    // Ancre invisible à la fin de la liste
                    Color.clear.frame(height: 1).id(bottomID)
                }
                .listStyle(.plain)
                .onChange(of: flowItems.count) { _ in
                    // Déclencheur pour défiler vers le bas
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            
            Button(action:toggleDecoding){Label(isDecoding ?"Arrêter":"Démarrer",systemImage:isDecoding ?"stop.circle.fill":"play.circle.fill").font(.title2.bold()).frame(maxWidth:.infinity)}.padding().background(isDecoding ?.red:.green).foregroundColor(.white).buttonStyle(.borderedProminent).tint(isDecoding ?.red:.green)
        }.navigationTitle("Flux Continu").navigationBarTitleDisplayMode(.inline).onTapGesture{isTextFieldFocused=false}.onChange(of:isTextFieldFocused){isFocused in if !isFocused, !userQuery.isEmpty{addThought(text:userQuery);userQuery=""}}
    }

    @ViewBuilder private func thoughtCell(text:String)->some View{HStack{Image(systemName:"bubble.left.fill").foregroundColor(.orange);Text(text).font(.body.italic());Spacer()}.padding().background(Color.orange.opacity(0.1)).cornerRadius(10)}
    
    #if USE_CORE_DATA
    @ViewBuilder private func sequenceCell(data:SequenceData)->some View{VStack(alignment:.leading,spacing:8){Text(data.timestamp,style:.time).font(.caption).foregroundColor(.secondary);Text(data.chartDecodedMessage ?? "").font(.system(.body,design:.monospaced));if !(data.oracleSequence ?? "").isEmpty{Text("[Oracle] \"\(data.oracleSequence!)\"").font(.caption).foregroundColor(.purple).lineLimit(1)}}.padding(.vertical,4)}
    #else
    @ViewBuilder private func sequenceCell(data:DecodedSequenceData)->some View{VStack(alignment:.leading,spacing:8){Text(data.timestamp,style:.time).font(.caption).foregroundColor(.secondary);Text(data.chartDecodedMessage).font(.system(.body,design:.monospaced));if !data.oracleSequence.isEmpty{Text("[Oracle] \"\(data.oracleSequence)\"").font(.caption).foregroundColor(.purple).lineLimit(1)}}.padding(.vertical,4)}
    #endif

    private func deleteItems(offsets:IndexSet){withAnimation{
        #if USE_CORE_DATA
        offsets.map{flowItems[$0]}.forEach(viewContext.delete)
        #else
        flowItems.remove(atOffsets: offsets)
        #endif
        saveContext()
    }}
    
    private func addThought(text:String){
        #if USE_CORE_DATA
        let i=ChatItem(context:viewContext);i.id=UUID();i.timestamp=Date();i.type="thought";i.thoughtText=text;
        #else
        flowItems.append(.userThought(id: UUID(), text: text))
        #endif
        saveContext()
    }
    
    private func toggleDecoding(){isDecoding.toggle();if isDecoding{startDecoding()}else{stopDecoding()}}
    private func stopDecoding(){decodingTask?.cancel();decodingTask=nil}
    
    private func startDecoding() {
        decodingTask = Task {
            while !Task.isCancelled {
                if await MainActor.run(body: { isTextFieldFocused }) { do { try await Task.sleep(nanoseconds: 500_000_000); continue } catch { break } }

                let numbers = (0..<Int.random(in: 8...15)).map { _ in UInt64.random(in: .min ... .max) }
                let longestSequenceResult = findLongestUTF8Sequence(from: numbers)
                let rawText = numbers.map { String($0) }.joined()
                guard rawText.count > 3 else { continue }

                let alignmentDigit = Int(String(rawText.prefix(1))) ?? 0
                let lengthDigits = Int(String(rawText.dropFirst().prefix(2))) ?? 0
                let messageDigits = String(rawText.dropFirst(3))
                let alignmentString = (alignmentDigit < 5) ? "GAUCHE" : "DROITE"
                let targetLength = (lengthDigits % 31) + 10
                var decodedChartMessage = generator.correspondancePerChart(message: messageDigits)
                if decodedChartMessage.count > targetLength { decodedChartMessage = String(decodedChartMessage.prefix(targetLength)) }
                else { decodedChartMessage = decodedChartMessage.padding(toLength: targetLength, withPad: "·", startingAt: 0) }

                await MainActor.run {
                    #if USE_CORE_DATA
                    let numbersData = try? JSONEncoder().encode(numbers)
                    let chatItem = ChatItem(context: viewContext)
                    chatItem.id = UUID()
                    chatItem.timestamp = Date()
                    chatItem.type = "sequence"
                    let sequenceData = SequenceData(context: viewContext)
                    sequenceData.id = UUID()
                    sequenceData.timestamp = chatItem.timestamp
                    sequenceData.numbers = numbersData
                    sequenceData.oracleSequence = longestSequenceResult.seq
                    sequenceData.oracleStartBit = Int64(longestSequenceResult.bit)
                    sequenceData.oracleByteLength = Int64(longestSequenceResult.len)
                    sequenceData.chartAlignment = alignmentString
                    sequenceData.chartTargetLength = Int64(targetLength)
                    sequenceData.chartDecodedMessage = decodedChartMessage
                    chatItem.sequence = sequenceData
                    #else
                    let sequenceData = DecodedSequenceData(numbers: numbers, oracleSequence: longestSequenceResult.seq, oracleStartBit: longestSequenceResult.bit, oracleByteLength: longestSequenceResult.len, chartAlignment: alignmentString, chartTargetLength: targetLength, chartDecodedMessage: decodedChartMessage)
                    flowItems.append(.decodedSequence(sequenceData))
                    #endif
                    saveContext()
                }
                
                do { try await Task.sleep(nanoseconds: 800_000_000) } catch { break }
            }
        }
    }
    
    private func saveContext(){
        #if USE_CORE_DATA
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        #endif
    }
}


// MARK: - SwiftUI App Entry Point
@main
struct NumberDecoderApp: App {
    #if USE_CORE_DATA
    let persistenceController = PersistenceController.shared
    #endif

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Oracle", systemImage: "wand.and.stars") }
                NavigationView { ContinuousDecodingView() }
                    .tabItem { Label("Flux Continu", systemImage: "infinity.circle.fill") }
            }
            #if USE_CORE_DATA
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            #endif
        }
    }
}

