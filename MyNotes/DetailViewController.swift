import UIKit
import Foundation

class DetailViewController: UIViewController {
    
    @IBOutlet weak var prompt: UILabel!
    @IBOutlet weak var goal1: UITextView!
    @IBOutlet weak var goal2: UITextView!
    @IBOutlet weak var goal3: UITextView!
    @IBOutlet weak var button1: UISegmentedControl!
    @IBOutlet weak var button2: UISegmentedControl!
    @IBOutlet weak var button3: UISegmentedControl!
    
    var behaviorPlanContentProvider: BehaviorPlanContentProvider?
    var feedbackContentProvider: FeedbackContentProvider?
    var myBehaviorPlan: BehaviorPlan?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        configureView()
    }
    
    // Display the note title and content
    func configureView() {
        if let student = myBehaviorPlan?.value(forKey: "student") as? String {
            navigationItem.title = student
            prompt.text = "Is \(student) accomplishing these goals?"
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
    
    func save() {
        let planId = myBehaviorPlan?.value(forKey: "id") as? String
        let goal1Text = button1.selectedSegmentIndex == 0 ? "no" : "yes"
        let goal2Text = button2.selectedSegmentIndex == 0 ? "no" : "yes"
        let goal3Text = button3.selectedSegmentIndex == 0 ? "no" : "yes"
        let newId = NSUUID().uuidString
        _ = feedbackContentProvider?.insertFeedbackDDB(id: newId, planId: planId!, goal1: goal1Text, goal2: goal2Text, goal3: goal3Text)
    }
    
    @IBAction func submitAction(_ sender: Any) {
        print("responses:")
        print("goal 1: \(button1.selectedSegmentIndex == 0 ? "no" : "yes")")
        print("goal 2: \(button2.selectedSegmentIndex == 0 ? "no" : "yes")")
        print("goal 3: \(button3.selectedSegmentIndex == 0 ? "no" : "yes")")
        
        save()
        
        let splitViewController = self.view.window!.rootViewController as! UISplitViewController
        if let masterNavigationController = splitViewController.viewControllers[0] as? UINavigationController {
            masterNavigationController.popViewController(animated: true)
        }
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "edit" {
            let editController = segue.destination as! EditViewController
            editController.myBehaviorPlan = myBehaviorPlan
            editController.detailViewController = self
            editController.behaviorPlanContentProvider = behaviorPlanContentProvider
        }
        else if segue.identifier == "feedback" {
            let feedbackController = segue.destination as! FeedbackViewController
            feedbackController.feedbackContentProvider = feedbackContentProvider
            feedbackController.planId = myBehaviorPlan?.value(forKey: "id") as? String
            feedbackContentProvider?.myFeedbackViewController = feedbackController
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

