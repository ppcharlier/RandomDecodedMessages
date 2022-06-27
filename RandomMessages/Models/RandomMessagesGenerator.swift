//
//  RandomMessagesGenerator.swift
//  RandomMessages
//
//  Created by Pierre-Philippe Charlier on 26/06/2022.
//

import Foundation

class RandomMessagesGenerator {

	var inputMessage: String = "[Here appears the question]"
	var charChart = [["0", " :D ", " :) ", " :( ", " <3 ", " :* ", " :'(", " >:) ", " O:) ", " :V "],
					 ["A", "1", "B", "C", "D", "E", "F", "G", "H", "I",],
					 [ "J", "K", "2", "L", "M", "N", "O", "P", "Q", "R", ],
					 [ "S", "T", "U", "3", "V", "W", "X", "Y", "Z", "#" ],
					 [ "%", "ç", "à", "a", "4", "b", "c", "d",  "e", "f" ],
					 [ "g", "h", "i", "j", "k", "5", "l", "m", "n", "o"],
					 [ "p", "q", "r", "s", "t", "u", "6", "v", "w", "x"],
					 [ "y", "z",  "(", ")", "{", "}", "[", "7","]", "@"],
					 [  "<", ">", "≤", "≥", "$", "\"", "+", "-","8", "*"],
					 [  "/", "%", "°", "&", "§", "$", "€", "¥", "é", "9"]
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

		for step in 0...3 {
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

//	func interpret(message: String) -> String {
//		var message_trad: String = ""
//		for a in message {
//
//			switch a {
//			case "0":
//				message_trad += ""
//			case "1":
//				message_trad += "Soi"
//			case "2":
//				message_trad += "Partenaire"
//			case "3":
//				message_trad += "Relation"
//			case "4":
//				message_trad += "Stabilité"
//			case "5":
//				message_trad += "Famille"
//			case "6":
//				message_trad += "Réflexion"
//			case "7":
//				message_trad += "Idée"
//			case "8":
//				message_trad += "Destructive"
//			case "9":
//				message_trad += "Constructive"
//
//			default:
//				message_trad += "?"
//			}
//			message_trad += " "
//		}
//		return message_trad
//	}

	func correspondancePerChart(message: String) -> String {
		var chartSelect = true
		var message_trad: String = ""

		var subchart: [String] =  charChart[9]

		for a in message {
			if chartSelect {
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

			} else {
				if let b = Int(a.description) {
					message_trad += subchart[b]
				}
			}
			chartSelect = !chartSelect
		}
		return message_trad
	}
}
