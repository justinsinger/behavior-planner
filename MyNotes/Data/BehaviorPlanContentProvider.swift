/*
 * Copyright 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file
 * except in compliance with the License. A copy of the License is located at
 *
 *    http://aws.amazon.com/apache2.0/
 *
 * or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for
 * the specific language governing permissions and limitations under the License.
 */

import Foundation
import CoreData
import UIKit
import AWSCore
import AWSPinpoint
import AWSDynamoDB
import AWSAuthCore

// The content provider for the internal Note database (Core Data)

public class BehaviorPlanContentProvider  {
    
    var myBehaviorPlans: [NSManagedObject] = []
    
    func getContext() -> NSManagedObjectContext {
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return managedContext
    }
    
    func insert(student: String, goal1: String, goal2: String, goal3: String) -> String {
        let newId = NSUUID().uuidString
        self.insert(id: newId, student: student, goal1: goal1, goal2: goal2, goal3: goal3)
        return newId
    }
    
    func insert(id: String, student: String, goal1: String, goal2: String, goal3: String) -> Void {
        
        // Get NSManagedObjectContext
        let managedContext = getContext()
        
        let entity = NSEntityDescription.entity(forEntityName: "BehaviorPlan",
                                                in: managedContext)!
        
        let myBehaviorPlan = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        myBehaviorPlan.setValue(NSDate(), forKeyPath: "created")
        myBehaviorPlan.setValue(id, forKeyPath: "id")
        myBehaviorPlan.setValue(student, forKeyPath: "student")
        myBehaviorPlan.setValue(goal1, forKeyPath: "goal1")
        myBehaviorPlan.setValue(goal2, forKeyPath: "goal2")
        myBehaviorPlan.setValue(goal3, forKeyPath: "goal3")
        
        do {
            try managedContext.save()
            myBehaviorPlans.append(myBehaviorPlan)
        } catch let error as NSError {
            print("Could not save behavior plan. \(error), \(error.userInfo)")
        }
    }
    
    func update(id: String, student: String, goal1: String, goal2: String, goal3: String)  {
        
        // Get NSManagedObjectContext
        let managedContext = getContext()
        
        let entity = NSEntityDescription.entity(forEntityName: "BehaviorPlan",
                                                in: managedContext)!
        
        let myBehaviorPlan = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        myBehaviorPlan.setValue(id, forKeyPath: "id")
        myBehaviorPlan.setValue(student, forKeyPath: "student")
        myBehaviorPlan.setValue(goal1, forKeyPath: "goal1")
        myBehaviorPlan.setValue(goal2, forKeyPath: "goal2")
        myBehaviorPlan.setValue(goal3, forKeyPath: "goal3")
        myBehaviorPlan.setValue(NSDate(), forKeyPath: "modified")
        
        do {
            try managedContext.save()
            myBehaviorPlans.append(myBehaviorPlan)
        } catch let error as NSError {
            print("Could not save behavior plan. \(error), \(error.userInfo)")
        }
    }
    
    public func delete(managedObjectContext: NSManagedObjectContext, managedObj: NSManagedObject, id: String!)  {
        let context = managedObjectContext
        context.delete(managedObj)
        
        do {
            try context.save()
            print("Deleted local NoteId: \(id)")
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved local delete error \(nserror), \(nserror.userInfo)")
        }
    }
    
    //Insert a note using Amazon DynamoDB
    func insertNoteDDB(id: String, student: String, goal1: String, goal2: String, goal3: String) -> String {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let planItem: BehaviorPlans = BehaviorPlans()
        
        planItem._userId = AWSIdentityManager.default().identityId
        planItem._id = id
        planItem._student = student
        planItem._goal1 = goal1
        planItem._goal2 = goal2
        planItem._goal3 = goal3
        planItem._created = NSDate().timeIntervalSince1970 as NSNumber
        planItem._modified = NSDate().timeIntervalSince1970 as NSNumber
        planItem._teachers = [" "]
        
        //Save a new item
        dynamoDbObjectMapper.save(planItem, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error on new plan: \(error)")
                return
            }
            print("New plan was saved to DDB.")
        })
        
        return planItem._id!
    }
    
    //Insert a note using Amazon DynamoDB
    func updateNoteDDB(id: String, student: String, goal1: String, goal2: String, goal3: String)  {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let planItem: BehaviorPlans = BehaviorPlans()
        
        planItem._userId = AWSIdentityManager.default().identityId
        planItem._id = id
        planItem._student = student.isEmpty ? " " : student
        planItem._goal1 = goal1.isEmpty ? " " : goal1
        planItem._goal2 = goal2.isEmpty ? " " : goal2
        planItem._goal3 = goal3.isEmpty ? " " : goal3
        planItem._modified = NSDate().timeIntervalSince1970 as NSNumber
        
        let updateMapperConfig = AWSDynamoDBObjectMapperConfiguration()
        updateMapperConfig.saveBehavior = .update //ignore any null value attributes and does not remove in database
        dynamoDbObjectMapper.save(planItem, configuration: updateMapperConfig, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print(" Amazon DynamoDB Save Error on plan update: \(error)")
                return
            }
            print("Existing plan updated in DDB.")
        })
    }
    
    //Delete a note using Amazon DynamoDB
    func deleteNoteDDB(id: String) {
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        let itemToDelete = BehaviorPlans()
        itemToDelete?._userId = AWSIdentityManager.default().identityId
        itemToDelete?._id = id
        
        dynamoDbObjectMapper.remove(itemToDelete!, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print(" Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("A plan was deleted in DDB.")
        })
    }
    
    func syncBehaviorPlansFromDDB(fetchedResultsController: NSFetchedResultsController<BehaviorPlan>) {
        // 0) Delete all local data
        let context = fetchedResultsController.managedObjectContext
        if let objects = fetchedResultsController.fetchedObjects {
            for plan in objects{
                //Delete Locally
                self.delete(managedObjectContext: context, managedObj: plan, id: plan.id)
            }
        }
        
        // 1) Configure the query looking for all the notes created by this user (userId => Cognito identityId)
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.default().identityId!
        ]
        
        // 2) Make the query and add all cloud notes to the local DB
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDbObjectMapper.query(BehaviorPlans.self, expression: queryExpression) { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("DynamoDB query request failed. Error: \(String(describing: error))")
            }
            if output != nil {
                print("Found [\(output!.items.count)] notes")
                for plans in output!.items {
                    if let planItem = plans as? BehaviorPlans {
                        self.insert(id: planItem._id!, student: planItem._student!, goal1: planItem._goal1!, goal2: planItem._goal2!, goal3: planItem._goal3!)
                    }
                }
            }
        }
    }
}
