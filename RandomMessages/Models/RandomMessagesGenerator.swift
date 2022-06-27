//
//  RandomMessagesGenerator.swift
//  RandomMessages
//
//  Created by Pierre-Philippe Charlier on 26/06/2022.
//

import Foundation

class RandomMessagesGenerator {

	var inputMessage: String = "[Here appears the question]"
	var charChart = [[ "0", "A", "B", "C", "D", "E", "F", "G", "H", "I" ],
					 [ "J", "1", "K", "L", "M", "N", "O", "P", "Q", "R"],
					 [ "S", "T", "2", "U", "V", "W", "X", "Y", "Z", " "],
					 [ "a", "b", "c", "3", "d", "e", "f", "g" ,"h", "i"],
					 [ "j", "k", "l", "m", "4", "n", "o", "p", "q", "r"],
					 [ "s", "t", "u", "v", "w", "5", "x", "y", "z", "%"],
					 [ "(", ")", "{", "}", "[", "]", "6", "$", "€", "¥"],
					 [ "<", ">", "≤", "≥", "+", "-", "*", "7", "/", "\\"],
					 [ "#", "@", "&", "§", "$", "%", "°", "\'", "8", "\""],
					 [ "é", "è", "ê", "á", "à", "â", "í", "ì", "î", "9"]
					]

	func kindlyAskAMessage() -> String {

		return ask()
	}

	func nervouslyAMessage() -> String {

		return ask()
	}

	private func ask() -> String {
//		sleep(1)
//		arc4random_stir()
//		let message_parts = arc4random()/UInt32.max*10 // * 999999
		var message_numbers : [UInt32] = []
		var message_string : String = ""

		for step in 0...1 {
			arc4random_stir()
			message_numbers.append(arc4random()) // * 999999
			message_string += String(message_numbers[step])
		}
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
		inputMessage = "Thank you very much :-)"
		sleep(200)
		inputMessage = "[Here appears the question]"
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

	func correspondancePerChart(message: String) -> String {
		var chartSelect = true
		var longChar = false
		var message_trad: String = ""

		var subchart: [String] =  charChart[9]

		for (index, a) in message.enumerated() {
			if chartSelect {
				switch a {
				case "0":
					subchart = charChart[0]
					longChar  = true
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

			} else {
				if longChar, let b = Int(a.description), let c = message.substring(with: index.advanced(by: 1)) {
					longChar = false

				} else if let b = Int(a.description) {
					message_trad += subchart[b]
				}
			}

			chartSelect = !longChar ? !chartSelect : false
			longChar = false
		}
		return message_trad
	}
}
