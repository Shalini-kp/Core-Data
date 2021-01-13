//
//  MasterDataViewController.swift
//  Core Data Framework
//

import UIKit
import CoreData

class MasterDataViewController: UIViewController {
    
    @IBOutlet weak var masterDataTableView: UITableView!
    
    var masterDataList: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load data from local (if want to get it from API, -- make use of ServiceRequestResponse class --)
        let url = Bundle.main.url(forResource: "MasterData", withExtension: "json")
        let data = NSData(contentsOf: url!)
        
        guard data != nil else { return }
        do {
            let object = try JSONSerialization.jsonObject(with: data! as Data, options: .allowFragments)
            if let jsonData = object as? NSArray {
                
                let startDate = Date()
                self.masterData(jsonData, completion: {
                    let executionTime = Date().timeIntervalSince(startDate)
                    print("Core Data executionTime =>\(executionTime)")
                })
            }
        } catch {
            print("Json parser error")
        }
    }
    
    func insert(_ managedContext: NSManagedObjectContext,_ dictionaryObj: Dictionary<String, Any>) {
        
        let obj = MasterData(context: managedContext)
        
        obj.id = dictionaryObj["_id"] as? String
        obj.name = dictionaryObj["name"] as? String
        obj.type = dictionaryObj["entityType"] as? String
        obj.parentId = dictionaryObj["parentId"] as? String
    }
    
    func update(_ managedContext: NSManagedObjectContext,_ fetchRequest: NSFetchRequest<NSManagedObject>,_ dictionaryObj: Dictionary<String, Any>) {
        do {
            let result = try managedContext.fetch(fetchRequest)
            let objectUpdate = result[0]
            objectUpdate.setValue(dictionaryObj["_id"] as! String, forKeyPath: "id")
            objectUpdate.setValue(dictionaryObj["name"] as? String, forKey: "name")
            objectUpdate.setValue(dictionaryObj["entityType"] as? String, forKeyPath: "type")
            objectUpdate.setValue(dictionaryObj["parentId"] as? String, forKey: "parentId")
        } catch {
            print("Error while updating.")
        }
    }
    
    func save(_ managedContext: NSManagedObjectContext) {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func fetch(_ managedContext: NSManagedObjectContext) -> [NSManagedObject] {
        
        var result = [NSManagedObject]()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MasterData")
        
        do {
            result = try managedContext.fetch(fetchRequest)
        } catch {
            print("Error while fetching the data.")
        }
        return result
    }
    
    func delete(_ managedContext: NSManagedObjectContext,_ fetchRequest: NSFetchRequest<NSManagedObject>) {
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            print("\n data before delete =>\(result.count)")
            
            if !result.isEmpty {
                for i in result {
                    managedContext.delete(i)
                }
            }
        } catch {
            print("Error while deleting the data.")
        }
        
    }
    
    //master data
    func masterData(_ jsonData: NSArray, completion: @escaping () -> ())
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        DispatchQueue.main.async {
        
            print("\n jsonData =>\(jsonData.count)\n managedContext.hasChanges =>\(managedContext.hasChanges)")
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MasterData")
            
            self.masterDataList = self.fetch(managedContext)
            print("\n Before masterDataList =>\(self.masterDataList.count)")
            
            self.delete(managedContext, fetchRequest)
            for i in jsonData {
                let dictionaryObj = i as! Dictionary<String, Any>
                
                let predicate = NSPredicate(format: "id == %@" , dictionaryObj["_id"] as? String ?? "")
                fetchRequest.predicate = predicate
                
                do {
                    let count = try managedContext.count(for: fetchRequest)
                    print("\n count =>\(count)\n managedContext.hasChanges =>\(managedContext.hasChanges)")
                    if count > 0 {
                        
                        self.update(managedContext, fetchRequest, dictionaryObj)
                    } else {
                        
                        self.insert(managedContext, dictionaryObj)
                    }
                    
                } catch let error as NSError {
                    print("Could not fetch count for checking if Item exists in the MasterData entity -MasterData-. \(error), \(error.userInfo)")
                }
                
            }
            
            self.save(managedContext)
            self.masterDataList = self.fetch(managedContext)
            print("\n masterDataList =>\(self.masterDataList.count)")
            
            self.masterDataTableView.reloadData()
            completion()
        }
    }
}

extension MasterDataViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "masterDataTableViewCellID")
        
        cell.textLabel?.text = masterDataList[indexPath.row].value(forKey: "name") as? String ?? ""
        return cell
    }
}


/*
 
 --------------   Another method to insert(mainly used to update)   ----------------
 
 let masterDataEntity = NSEntityDescription.entity(forEntityName: "MasterData", in: managedContext)!
 let user = NSManagedObject(entity: masterDataEntity, insertInto: managedContext)
 user.setValue(dictionaryObj["_id"] as! String, forKeyPath: "id")
 user.setValue(dictionaryObj["name"] as? String, forKey: "name")
 user.setValue(dictionaryObj["entityType"] as? String, forKeyPath: "type")
 user.setValue(dictionaryObj["parentId"] as? String, forKey: "parentId")
 
 ------------------     Background process     ---------------------
 let managedContext = appDelegate.persistentContainer.newBackgroundContext()
 managedContext.automaticallyMergesChangesFromParent = true
 
 DispatchQueue.global(qos: .background).async {
 managedContext.performAndWait {
 }}
 
 -------------------    User defined thread   -----------------------
 let concurrentQueue = DispatchQueue(label: "com.masterData.concurrent", attributes: .concurrent)
 concurrentQueue.async {
 }
 
 -------------------    Predicate   ------------------
 let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [predicate])
 
 let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MasterData")
 fetchRequest.fetchLimit =  1
 fetchRequest.predicate = predicate
 
 */
