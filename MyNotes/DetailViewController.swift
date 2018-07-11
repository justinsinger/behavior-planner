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
import UIKit
import Foundation
import CoreData
import CoreGraphics

/* DetailViewController is a single note detail screen
*  You can view note details and/or edit the note title or content
*  The note details auto-save; no need to manually save note details
*/
class DetailViewController: UIViewController {
    
    var behaviorPlanContentProvider: BehaviorPlanContentProvider? = nil
    
    @IBOutlet weak var student: UITextField!
    @IBOutlet weak var goal1: UITextView!
    @IBOutlet weak var goal2: UITextView!
    @IBOutlet weak var goal3: UITextView!
    
    
    // Assign all the textfields to this action for keyboard collapse
    @IBAction func resignKeyboardTextField(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    static var id: String?
    
    // Timer! Property for auto-saving of a note
    var autoSaveTimer: Timer!
    
    var behaviorPlans: [NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Notes contentProvider
        behaviorPlanContentProvider = BehaviorPlanContentProvider()
        
        // Start the auto-save timer to call autoSave() every 2 seconds
        autoSaveTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(autoSave), userInfo: nil, repeats: true)
        
        // Prepare textfields with rounded corners
        student.layer.borderWidth = 0.5
        student.layer.cornerRadius = 5
        goal1.layer.borderWidth = 0.5
        goal1.layer.cornerRadius = 5
        goal2.layer.borderWidth = 0.5
        goal2.layer.cornerRadius = 5
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        student.leftViewMode = .always
        student.leftView = paddingView
       
        // Do any additional setup after loading the view
        configureView()
    }
    
    var myBehaviorPlan: BehaviorPlan? {
        
        didSet {
            // Set the note Id if passed in from the MasterView
            DetailViewController.id = myBehaviorPlan?.value(forKey: "id") as? String
            
            // Update the view with passed in note title and content.
            configureView()
        }
    }
    
    // Display the note title and content
    func configureView() {
        
        if let title = myBehaviorPlan?.value(forKey: "student") as? String {
            student?.text = title
        }
        
        if let content = myBehaviorPlan?.value(forKey: "goal1") as? String {
            goal1?.text = content
        }
        if let content = myBehaviorPlan?.value(forKey: "goal2") as? String {
            goal2?.text = content
        }
    }
    
    func autoSave() {
        if (DetailViewController.id == nil) // Insert
        {
            let id = behaviorPlanContentProvider?.insert(student: " ", goal1: " ", goal2: " ", goal3: " ")
            _ = behaviorPlanContentProvider?.insertNoteDDB(id: id!, student: " ", goal1: " ", goal2: " ", goal3: " ")
            DetailViewController.id = id
        }
        else // Update
        {
            let planId = DetailViewController.id
            let studentText = self.student.text
            let goal1Text = self.goal1.text
            let goal2Text = self.goal2.text
            let goal3Text = ""
            behaviorPlanContentProvider?.update(id: planId!, student: studentText!, goal1: goal1Text!, goal2: goal2Text!, goal3: goal3Text)
            behaviorPlanContentProvider?.updateNoteDDB(id: planId!, student: studentText!, goal1: goal1Text!, goal2: goal2Text!, goal3: goal3Text)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop the auto-save timer
        if autoSaveTimer != nil {
            autoSaveTimer.invalidate()
        }
        
        // Update the note one last time unless a note was never created
        if let planId = DetailViewController.id {
            behaviorPlanContentProvider?.update(id: planId, student: self.student.text!, goal1: self.goal1.text!, goal2: self.goal2.text!, goal3: "")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DetailViewController.id = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Dismiss keyboard when user taps on view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Dismiss keyboard when user taps the return key on the keyboard after editing
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

