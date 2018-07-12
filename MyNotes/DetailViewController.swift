
import UIKit
import Foundation

class DetailViewController: UIViewController {
    
    @IBOutlet weak var student: UITextField!
    @IBOutlet weak var goal1: UITextView!
    @IBOutlet weak var goal2: UITextView!
    @IBOutlet weak var goal3: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "edit" {
            let editController = segue.destination as! EditViewController
            editController.myBehaviorPlan = myBehaviorPlan
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

