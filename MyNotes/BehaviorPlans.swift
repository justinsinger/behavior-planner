//
//  BehaviorPlans.swift
//  MySampleApp
//
//
// Copyright 2018 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.21
//

import Foundation
import UIKit
import AWSDynamoDB

class BehaviorPlans: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _userId: String?
    var _modified: NSNumber?
    var _created: NSNumber?
    var _goal1: String?
    var _goal2: String?
    var _goal3: String?
    var _id: String?
    var _student: String?
    var _teachers: [String]?
    
    class func dynamoDBTableName() -> String {

        return "iosnotesapp-mobilehub-2027009978-behaviorPlans"
    }
    
    class func hashKeyAttribute() -> String {

        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {

        return "_modified"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_userId" : "userId",
               "_modified" : "modified",
               "_created" : "created",
               "_goal1" : "goal1",
               "_goal2" : "goal2",
               "_goal3" : "goal3",
               "_id" : "id",
               "_student" : "student",
               "_teachers" : "teachers",
        ]
    }
}
