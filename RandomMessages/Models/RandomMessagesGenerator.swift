//
//  RandomMessagesGenerator.swift
//  RandomMessages
//
//  Created by Pierre-Philippe Charlier on 26/06/2022.
//

import Foundation

class RandomMessagesGenerator {

    let charVersion: String = "0.1"
    
	var messageFromUser: String = "[message]"
    
    var outputMessage: String = "[output]"
    
    enum ChartType {
        case type1
        case type2
    }
    
	// Method Generated & Normalised
//	var charsAlpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
//	var charsSpecial = "#@&é\"'(§è!çà)-_^¨$*ù%´`£=+:/;.,?"
//	var charsNumeric = "1234567890"
//
////	init() {
////		var cn: Int = 0
////		var sn: Int = 0
////		var nn: Int = 0
////
////		var str: String = ""
////
////		repeat {
////			repeat {
////				repeat {
////					var idx: String.Index
////					idx.samePosition(in: <#T##String#>)
////					str.append(charsAlpha.substring(to: idx))
////
////				} while cn < charsAlpha.count
////			} while sn < charsSpecial.count
////		} while nn < charsNumeric.count
////
////	}
//
//	var charChart3 = [[String]]()
//
//		// Method HARDCODED
	var charChart2 = [[ "0", "A", "B", "C", "D", "E", "F", "G", "H", "I"],
					 [ "J", "1", "K", "L", "M", "N", "O", "P", "Q", "R"],
					 [ "S", "T", "2", "U", "V", "W", "X", "Y", "Z", " "],
					 [ "a", "b", "c", "3", "d", "e", "f", "g" ,"h", "i"],
					 [ "j", "k", "l", "m", "4", "n", "o", "p", "q", "r"],
					 [ "s", "t", "u", "v", "w", "5", "x", "y", "z", "."],
					 [ "[", "{", "(", ")", "}", "]", "6", "§", "¥", "$"],
					 [ "<", ">", "≤", "≥", "+", "-", "*", "7", "/", "\\"],
					 [ "#", "@", "&", "%", "£", "€", "°", "\'","8", "\""],
					 [ "´", "`", "^", "¨", "~", "æ", "œ", "\t", "\n", "9"]
	]
		// Method HARDCODED
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

	func kindlyAskAMessage() -> String {

		return decodeFromRandom()
	}

	func nervouslyAMessage() -> String {

		return decodeFromRandom()
	}

	private func decodeFromRandom() -> String {
//		sleep(1)
//		arc4random_stir()
//		let message_parts = arc4random()/UInt32.max*10 // * 999999
		var message_string : String = ""
		var message_add: String
		var remIter: Int = 1 + Int(arc4random()) % 3
		repeat {
			arc4random_stir()
			message_add = String(arc4random())
			message_string += message_add
			remIter -= 1
        } while message_add.count % 2 != 0 && remIter > 0
//		} while message_add.count % 2 == 1 && remIter > 0
//		sleep(200)
//		arc4random_stir()
//		let message_number1 = arc4random() // * 999999
//
//		sleep(200)
//		arc4random_stir()
//		let message_number2 = arc4random() // * 999999
//		let message_string = String(message_number1) + String(message_number2)

		return "\(message_string)"
	}

	func thanks() {
		messageFromUser = "Merci beaucoup / Bedankt / Thank you :-)"
		sleep(3)
		messageFromUser = "[Ici apparaîtra le message / Hier zal iets gezegd worden / Here will one say something :-)]"
	}

	func interpret(message: String) -> String {
		var message_trad: String = ""
		for a in message {

			switch a {
			case "0":
				message_trad += "Pas/Non/Symbolique/Rien"
			case "1":
				message_trad += "Soi/La Personne/Ses pensées/Ses actes"
			case "2":
				message_trad += "L'autre/Le partenaire/l'inconnu/l'étranger"
			case "3":
				message_trad += "Rapport à/Lien à/Relation avec/L'intimité avec"
			case "4":
				message_trad += "Stabilité"
			case "5":
				message_trad += "Famille/Groupe/Communauté/Société/Le Monde"
			case "6":
				message_trad += "Pensée/Réflexion/L'introspection/La Sagesse"
			case "7":
				message_trad += "Idée/La planification/La mise en œuvre/L'accomplissement"
			case "8":
				message_trad += "Humour"
			case "9":
				message_trad += "Travail"

			default:
				message_trad += "."
			}
			message_trad += "\n"
		}
		return message_trad
	}
    
    func correspondancePerChart(message: String, chartType: ChartType = .type1) -> String {
        switch(chartType) {
        case .type1 :
            return correspondancePerChart(message: message, charChart: charChart)
        case .type2 :
            return correspondancePerChart(message: message, charChart: charChart2)
        }
    }

    func invCorrespondancePerChart(message: String, chartType: ChartType = .type1) -> String {
        switch(chartType) {
        case .type1 :
            return invCorrespondancePerChart(message: message, charChart: charChart)
        case .type2 :
            return invCorrespondancePerChart(message: message, charChart: charChart2)
        }
    }
    func correspondancePerChart(message: String, charChart: [[String]]) -> String {
		var chartSelect = true
		var message_trad: String = ""

		var subchart: [String] =  charChart[9]

		for (index, a) in message.enumerated() {
			if chartSelect || index == message.count-1 {
				switch a {
				case "0":
					subchart = charChart[0]
				case "1":
					subchart = charChart[1]
				case "2":
					subchart = charChart[2]
				case "3":
					subchart = charChart[3]
				case "4":
					subchart = charChart[4]
				case "5":
					subchart = charChart[5]
				case "6":
					subchart = charChart[6]
				case "7":
					subchart = charChart[7]
				case "8":
					subchart = charChart[8]
				case "9":
					subchart = charChart[9]

				default:
					subchart = ["?", "?", "?", "?", "?", "?", "?", "?", "?", "?"]
				}

			}

			if !chartSelect || index == message.count-1, let b = Int(a.description) {
			message_trad += subchart[b]
			}


			chartSelect = !chartSelect
		}
		return message_trad
	}

    func invCorrespondancePerChart(message: String, charChart: [[String]]) -> String {
		var chartSelect = true
		var message_trad: String = ""

		var subchart: [String] =  charChart[9]

		for (index, a) in message.reversed().enumerated() {
			if chartSelect || index == message.count-1 {
				switch a {
				case "0":
					subchart = charChart[0]
				case "1":
					subchart = charChart[1]
				case "2":
					subchart = charChart[2]
				case "3":
					subchart = charChart[3]
				case "4":
					subchart = charChart[4]
				case "5":
					subchart = charChart[5]
				case "6":
					subchart = charChart[6]
				case "7":
					subchart = charChart[7]
				case "8":
					subchart = charChart[8]
				case "9":
					subchart = charChart[9]

				default:
					subchart = ["?", "?", "?", "?", "?", "?", "?", "?", "?", "?"]
				}

			}

			if !chartSelect || index == message.count-1, let b = Int(a.description) {
				message_trad += subchart[b]
			}


			chartSelect = !chartSelect
		}
		return message_trad
	}
}
