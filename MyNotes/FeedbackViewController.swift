import UIKit

class FeedbackViewController: UITableViewController {
    
    var feedbackContentProvider: FeedbackContentProvider? = nil
    var planId: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        feedbackContentProvider?.syncFeedbackFromDDB(planId: planId!)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = feedbackContentProvider?.myFeedbacks.count else {
            return 0
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackCell", for: indexPath) as! FeedbackCell
        
        let feedback = feedbackContentProvider?.myFeedbacks[indexPath.row]
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy hh:mm a"
        let timestamp = feedback!._modified
        let date = NSDate(timeIntervalSince1970: TimeInterval(timestamp!))
        cell.cellTitle.text = dateFormatterPrint.string(from: date as Date)
        
        let green = UIColor(red:0.00, green:0.5, blue:0.00, alpha:1.0)
        cell.goal1.selectedSegmentIndex = feedback?._goal1Feedback == "yes" ? 1 : 0
        if (feedback?._goal1Feedback == "yes") {
            cell.goal1.tintColor = green
        }
        cell.goal2.selectedSegmentIndex = feedback?._goal2Feedback == "yes" ? 1 : 0
        if (feedback?._goal2Feedback == "yes") {
            cell.goal2.tintColor = green
        }
        cell.goal3.selectedSegmentIndex = feedback?._goal3Feedback == "yes" ? 1 : 0
        if (feedback?._goal3Feedback == "yes") {
            cell.goal3.tintColor = green
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
