
import UIKit
import Foundation
import CoreData

class EditViewController: UIViewController {
    
    var behaviorPlanContentProvider: BehaviorPlanContentProvider? = nil
    weak var detailViewController: DetailViewController? = nil
    
    @IBOutlet weak var student: UITextField!
    @IBOutlet weak var goal1: UITextView!
    @IBOutlet weak var goal2: UITextView!
    @IBOutlet weak var goal3: UITextView!
    
    static var id: String?
    
    // Assign all the textfields to this action for keyboard collapse
    @IBAction func resignKeyboardTextField(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    // Timer! Property for auto-saving of a note
    var autoSaveTimer: Timer!
    
    var behaviorPlans: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Notes contentProvider
        behaviorPlanContentProvider = BehaviorPlanContentProvider()
        
        // Start the auto-save timer to call autoSave() every 2 seconds
        autoSaveTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(autoSave), userInfo: nil, repeats: true)
        
        // Prepare textfields with rounded corners
        student.layer.borderWidth = 0.5
        student.layer.cornerRadius = 5
        goal1.layer.borderWidth = 0.5
        goal1.layer.cornerRadius = 5
        goal2.layer.borderWidth = 0.5
        goal2.layer.cornerRadius = 5
        goal3.layer.borderWidth = 0.5
        goal3.layer.cornerRadius = 5
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        student.leftViewMode = .always
        student.leftView = paddingView
        
        // Do any additional setup after loading the view
        configureView()
    }
    
    var myBehaviorPlan: BehaviorPlan? {
        didSet {
            // Set the note Id if passed in from the MasterView
            EditViewController.id = myBehaviorPlan?.value(forKey: "id") as? String
            
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
        if let content = myBehaviorPlan?.value(forKey: "goal3") as? String {
            goal3?.text = content
        }
    }
    
    func autoSave() {
        if (EditViewController.id == nil) // Insert
        {
            let id = behaviorPlanContentProvider?.insert(student: " ", goal1: " ", goal2: " ", goal3: " ")
            _ = behaviorPlanContentProvider?.insertNoteDDB(id: id!, student: " ", goal1: " ", goal2: " ", goal3: " ")
            EditViewController.id = id
        }
        let planId = EditViewController.id
        let studentText = self.student.text
        let goal1Text = self.goal1.text
        let goal2Text = self.goal2.text
        let goal3Text = self.goal3.text
        behaviorPlanContentProvider?.update(id: planId!, student: studentText!, goal1: goal1Text!, goal2: goal2Text!, goal3: goal3Text!)
        behaviorPlanContentProvider?.updateNoteDDB(id: planId!, student: studentText!, goal1: goal1Text!, goal2: goal2Text!, goal3: goal3Text!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop the auto-save timer
        if autoSaveTimer != nil {
            autoSaveTimer.invalidate()
        }
        
        autoSave()
        if let detail = detailViewController {
            detail.myBehaviorPlan?.student = self.student.text!
            detail.myBehaviorPlan?.goal1 = self.goal1.text!
            detail.myBehaviorPlan?.goal2 = self.goal2.text!
            detail.myBehaviorPlan?.goal3 = self.goal3.text!
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        EditViewController.id = nil
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
