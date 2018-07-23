import Foundation
import CoreData
import UIKit
import AWSCore
import AWSPinpoint
import AWSDynamoDB
import AWSAuthCore


public class FeedbackContentProvider  {
    
    var myFeedbacks: [Feedback] = []
    weak var myFeedbackViewController: FeedbackViewController? = nil
    
    func insertFeedbackDDB(id: String, planId: String, goal1: String, goal2: String, goal3: String) -> String {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let feedback: Feedback = Feedback()
        
        feedback._userId = AWSIdentityManager.default().identityId
        feedback._planId = planId.isEmpty ? " " : planId
        feedback._id = id
        feedback._teacher = " "
        feedback._goal1Feedback = goal1
        feedback._goal2Feedback = goal2
        feedback._goal3Feedback = goal3
        feedback._created = NSDate().timeIntervalSince1970 as NSNumber
        feedback._modified = NSDate().timeIntervalSince1970 as NSNumber
        
        //Save a new item
        dynamoDbObjectMapper.save(feedback, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error on new feedback: \(error)")
                return
            }
            print("New feedback was saved to DDB.")
        })
        
        return feedback._id!
    }
    
    func updateFeedbackDDB(id: String, planId: String, goal1: String, goal2: String, goal3: String)  {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let feedback: Feedback = Feedback()
        
        feedback._userId = AWSIdentityManager.default().identityId
        feedback._planId = planId.isEmpty ? " " : planId
        feedback._id = id
        feedback._teacher = " "
        feedback._goal1Feedback = goal1.isEmpty ? " " : goal1
        feedback._goal2Feedback = goal2.isEmpty ? " " : goal2
        feedback._goal3Feedback = goal3.isEmpty ? " " : goal3
        feedback._modified = NSDate().timeIntervalSince1970 as NSNumber
        
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .updateSkipNullAttributes //ignore any null value attributes and does not remove in database
        dynamoDbObjectMapper.save(feedback, configuration: updateMapperConfig, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print(" Amazon DynamoDB Save Error on plan update: \(error)")
                return
            }
            print("Existing plan updated in DDB.")
        })
    }
    
    func deleteFeedbackDDB(id: String) {
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let itemToDelete = Feedback()
        itemToDelete?._userId = AWSIdentityManager.default().identityId
        itemToDelete?._id = id
        
        dynamoDbObjectMapper.remove(itemToDelete!, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print(" Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("A feedback was deleted in DDB.")
        })
    }
    
    func syncFeedbackFromDDB(planId: String) {
        // Delete all local data
        self.myFeedbacks = []
        
        // 1) Configure the query looking for all the notes created by this user (userId => Cognito identityId)
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#planId = :planId"
        
        queryExpression.expressionAttributeNames = [
            "#planId": "planId",
        ]
        queryExpression.expressionAttributeValues = [
            ":planId": planId
        ]
        
        // 2) Make the query and add all cloud notes to the local DB
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.query(Feedback.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("DynamoDB query request failed. Error: \(String(describing: error))")
            }
            if output != nil {
                print("Found [\(output!.items.count)] notes")
                
                for plans in output!.items {
                    if let feedback = plans as? Feedback {
                        self.myFeedbacks.append(feedback)
                    }
                }
                
                self.myFeedbacks.sort(by: {$0._modified!.intValue > $1._modified!.intValue})
                self.myFeedbackViewController?.tableView.reloadData()
            }
        }
    }
}

