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
import CoreData
import Foundation

import AWSCore
import AWSPinpoint
import AWSAuthCore
import AWSAuthUI

/*
 * MasterViewController displays all the stored notes and allows a
 * user to create a new note, select an existing note, and swipe to delete a note.
*/
class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var _detailViewController: DetailViewController? = nil
    var _noteContentProvider: NotesContentProvider? = nil
    
    // NSFetchedResultsController as an instance variable of table view controller
    // to manage the results of a Core Data fetch request and display data to the user.
    var _fetchedResultsController: NSFetchedResultsController<Note>? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var notes: [NSManagedObject] = []
    
    // MARK: - Fetched results controller
    // Initialization of the NSFetchedResultsController.
    var fetchedResultsController: NSFetchedResultsController<Note> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        return _fetchedResultsController!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate sign-in UI from the SDK library
        self.promptLogin()

        managedObjectContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        //Initialize Note contentProvider
        _noteContentProvider = NotesContentProvider()
        
        title = "Behavior Plans"

        // Configure the add ('+') button
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewNote(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        // Configure the logout button
        let logoutButton = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(logout(_:)))
        navigationItem.leftBarButtonItem = logoutButton
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            _detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        _noteContentProvider?.syncNotesFromDDB(fetchedResultsController: fetchedResultsController)
    }

    func insertNewNote(_ sender: Any) {
        self.performSegue(withIdentifier: "showDetail", sender: (Any).self);
    }
    
    func logout(_ sender: Any) {
        // Declare Alert message
        let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            AWSSignInManager.sharedInstance().logout(completionHandler: {_,_ in
                self.promptLogin()
            })
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            return
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func promptLogin() {
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            AWSAuthUIViewController
                .presentViewController(with: self.navigationController!,
                                       configuration: nil,
                                       completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                                        if error != nil {
                                            print("Error occurred: \(String(describing: error))")
                                        } else {
                                            // Sign in successful.
                                        }
                })
        }

    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.myNote = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - table view boiler plate stuff
    // Table View Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Trying to reuse a cell
        let cellIdentifier = "ElementCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        let event = fetchedResultsController.object(at: indexPath)
        
        configureCell(cell, withEvent: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _ = indexPath
        self.performSegue(withIdentifier: "showDetail", sender: indexPath);
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the note item to be editable.
        return true
    }

    // Integrating the Fetched Results Controller with the Table View Data Source
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            let noteObj = fetchedResultsController.object(at: indexPath)
            let noteId = fetchedResultsController.object(at: indexPath).noteId
            
            //Delete Note Locally
            _noteContentProvider?.delete(managedObjectContext: context, managedObj: noteObj, noteId: noteId)
            
            //Delete Note in DynamoDB
            _noteContentProvider?.deleteNoteDDB(noteId: noteId!)
        }
    }

    func configureCell(_ cell: UITableViewCell, withEvent event: Note) {
        cell.textLabel!.text = "Title: " + event.title!
        cell.detailTextLabel?.text = event.content
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    // Called when user swipes and selects "Delete"
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Note)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Note)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}
