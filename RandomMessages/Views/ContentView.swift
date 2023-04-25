//
//  ContentView.swift
//  RandomMessages
//
//  Created by Pierre-Philippe Charlier on 26/06/2022.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    static private var messagesGenerator = RandomMessagesGenerator()
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trial.timestamp, ascending: false)],
        animation: .default)
    var items: FetchedResults<Trial>
    
    @State
    var thougths: String = "Hello ^^"
    
    var body: some View {
        NavigationView {
            VStack {
                Text("RAM_PROMPT")
                Divider()
                TextField(LocalizedStringKey("RAM_PLACEHOLDER"), text: $thougths).padding()
                List {
                    ForEach(items) { item in
                        VStack {
                            NavigationLink {
                                //                                ScrollView {
                                ScrollView {
                                    Text("\(item.thoughts!)")
                                    Text("Item at \(item.timestamp!, formatter: detailDateFormatter)\n\(item.result!)")
                                    
                                    if let _ = item.result {
                                        HStack {
                                            Text("Chart Type 1 :")
//#if !targetEnvironment(simulator)
                                            AttributedText(attributedString:  parseText(item.chart1A))
//#else
//                                            Text(item.chart1A)
//                                                .font(.system(.body, design: .monospaced))
//#endif
                                        }
                                        
                                        Divider()
                                        HStack {
                                            Text("Chart Type 1 Inverted :")
//#if !targetEnvironment(simulator)
                                            AttributedText(attributedString: parseText(item.chart1B))
//#else
//                                            Text(item.chart1B)
//                                                .font(.system(.body, design: .monospaced))
//
//#endif
                                        }
                                        
                                        Divider()
                                        HStack {
                                            Text("Chart Type 2 :")
//#if !targetEnvironment(simulator)
                                            AttributedText(attributedString: parseText(item.chart2A))
//#else
//                                            Text(item.chart2A)
//                                                .font(.system(.body, design: .monospaced))
//#endif
                                        }
                                        Divider()
                                        HStack {
                                            Text("Chart Type 2 Inverted :")
//#if targetEnvironment(simulator)
//                                            Text(ContentView.messagesGenerator.invCorrespondancePerChart(message: item.message ?? "", chartType: .type2))
//                                                .font(.system(.body, design: .monospaced))
//#else
                                            AttributedText(attributedString: parseText(item.chart2B))
//#endif
                                        }
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading){
                                    Text("Item at \(item.timestamp!,formatter: dateFormatter)")
                                    Text("Raw data: \(item.result!)")
                                    Text("Thoughts : \(item.thoughts!)")
                                    Divider()
                                    Text(item.chart1A)
                                    Text(item.chart1B)
                                    Text(item.chart2A)
                                    Text(item.chart2B)
                                }
                            }
                            
                        
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    //                ToolbarItem {
                    //                    Button(action: addItem) {
                    //                        Label("Add Item", systemImage: "plus")
                    //                    }
                    //
                    //                }
                    ToolbarItem {
                        Button(action: sendMessage) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                
                
            }
            
        }
    }
    
    func parseText(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "")
        
        var charAttributes: [Character: [NSAttributedString.Key: Any]] = [:]
        
        let characters = Array(text)
        for char in characters {
            if charAttributes[char] == nil {
                let randomColor = UIColor(red: .random(in: 0.5...1),
                                          green: .random(in: 0.5...1),
                                          blue: .random(in: 0.5...1),
                                          alpha: 1)
                let randomFontWeight: UIFont.Weight = [.regular, .medium, .bold, .heavy].randomElement()!
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: randomColor,
                    .font: UIFont.monospacedSystemFont(ofSize: 17, weight: randomFontWeight)
                ]
                charAttributes[char] = attributes
            }
            
            let attributedChar = NSAttributedString(string: String(char), attributes: charAttributes[char])
            attributedString.append(attributedChar)
        }
        
        return attributedString
    }
    
    
    private func sendMessage() {
        withAnimation {
            let newItem = Trial(context: viewContext)
            newItem.timestamp = Date()
            ContentView.messagesGenerator.messageFromUser = "[Thougths:]\(self.thougths)"
            newItem.thoughts = self.thougths
            newItem.result = ContentView.messagesGenerator.kindlyAskAMessage()
            
            do {
                try viewContext.save()
                
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            self.thougths = ""
        }
    }
    
    // MARK: Separator formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = .none
        return formatter
    }()
    private let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = .none
        return formatter
    }()
    
    private func addItem() {
        withAnimation {
            let newItem = Trial(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(thougths: "Hello :-) I'm trying my randomness reading app ^^").environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
