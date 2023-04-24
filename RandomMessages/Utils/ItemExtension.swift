//
//  MessageExtension.swift
//  RandomDecodedMessages
//
//  Created by Pierre-Philippe Charlier on 24/04/2023.
//

import Foundation

extension Item {
    
    public var chart1A : String {
        let rmg = RandomMessagesGenerator()
        if let msg = self.message {
            return  rmg.correspondancePerChart(message: msg, chartType: .type1)
        }else{
            return ""
        }
        
    }
    
    public var chart1B : String {
        let rmg = RandomMessagesGenerator()
        if let msg = self.message {
            return  rmg.invCorrespondancePerChart(message: msg, chartType: .type1)
        }else{
            return ""
        }
    }
    
    public var chart2A : String {
        let rmg = RandomMessagesGenerator()
        if let msg = self.message {
            return  rmg.correspondancePerChart(message: msg, chartType: .type2)
        }else{
            return ""
        }
    }
    
    public var chart2B : String {
        let rmg = RandomMessagesGenerator()
        if let msg = self.message {
            return  rmg.invCorrespondancePerChart(message: msg, chartType: .type2)
        }else{
            return ""
        }
    }
}
