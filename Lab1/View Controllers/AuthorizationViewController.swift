import UIKit
import SQLite3

class User
{
    var firstName: String?
    var lastName: String?
    var country: String?
    var email: String?
    var password: String?
    
    init (firstName: String?, lastName: String?, country: String?, email: String?, password: String?)
    {
        self.firstName = firstName
        self.lastName = lastName
        self.country = country
        self.email = email
        self.password = password
    }
}

class AuthorizationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{    
    @IBOutlet weak var mainFixedLabel: UILabel!
    
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var getMoreInfoButton: UIButton!

    @IBOutlet weak var createNewButton: UIButton!
    
    var indexInDb: Int!, rowCount: Int!
    var mainEmail: String!
    var userList = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customBackButton()
        
        setUpElements()
        
        fillTheData()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(true)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func customBackButton()
    {
        let customBackButton = UIBarButtonItem(image: UIImage(named: "backArrow") , style: .plain, target: self, action: #selector(backAction(sender:)))
        customBackButton.imageInsets = UIEdgeInsets(top: 2, left: -8, bottom: 0, right: 0)
        navigationItem.leftBarButtonItem = customBackButton
    }
    
    @objc func backAction(sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        userList.removeAll()
        var db, stmt: OpaquePointer?
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        sqlite3_open(fileURL.path, &db)
        
        let queryString = "SELECT * FROM Users"
        sqlite3_prepare(db, queryString, -1, &stmt, nil)
        
        while (sqlite3_step(stmt) == SQLITE_ROW)
        {
            userList.append(User(firstName: String(cString: sqlite3_column_text(stmt, 1)), lastName: String(cString: sqlite3_column_text(stmt, 2)), country: String(cString: sqlite3_column_text(stmt, 3)), email: String(cString: sqlite3_column_text(stmt, 4)), password: String(cString: sqlite3_column_text(stmt, 5))))
        }
        
        sqlite3_finalize(stmt)
        sqlite3_close_v2(db)
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
        let user: User
        user = userList[indexPath.row]
        cell.textLabel?.text = user.firstName! + " (" + user.email! + ")"
        return cell
    }
    
    func setUpElements()
    {
        editButton.layer.borderWidth = 1.5
        editButton.layer.cornerRadius = 20
        
        deleteButton.layer.borderWidth = 1.5
        deleteButton.layer.cornerRadius = 20
        
        getMoreInfoButton.layer.borderWidth = 1.5
        getMoreInfoButton.layer.cornerRadius = 20
        
        createNewButton.layer.borderWidth = 1.5
        createNewButton.layer.cornerRadius = 20
    }
    
    func fillTheData()
    {
        var counter: Int = 1
        var db, stmt: OpaquePointer?
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        sqlite3_open(fileURL.path, &db)
        
        let queryString = "SELECT * FROM Users"
        sqlite3_prepare(db, queryString, -1, &stmt, nil)
        
        while counter != indexInDb
        {
            sqlite3_step(stmt)
            counter += 1
        }
        
        sqlite3_step(stmt)
        mainFixedLabel.text = String(cString: sqlite3_column_text(stmt, 1))
        mainEmail = String(cString: sqlite3_column_text(stmt, 4))
            
        sqlite3_finalize(stmt)
        sqlite3_close_v2(db)
    }
    
    func deleteInDatabase(email: String)
    {
        var db, deleteStatement: OpaquePointer?
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        sqlite3_open(fileURL.path, &db)
        let deleteStatementString = "DELETE FROM Users WHERE email LIKE '\(email)'"
        sqlite3_prepare(db, deleteStatementString, -1, &deleteStatement, nil)
        
        if sqlite3_step(deleteStatement) == SQLITE_DONE
        {
            let ac = UIAlertController(title: "Delete user", message: "User was successfully deleted!", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            ac.addAction(okAction)
            self.present(ac, animated: true)
        }
        else
        {
            print("Could not delete user.")
        }
        
        sqlite3_finalize(deleteStatement)
        sqlite3_close_v2(db)
    }
    
    
    @IBAction func editButtonTapped(_ sender: Any)
    {
        let regViewController = storyboard?.instantiateViewController(identifier: "RegVC") as? RegistrationViewController
        navigationController?.pushViewController(regViewController!, animated: false)
        
        regViewController?.firstNameToEdit = userList[indexInDb - 1].firstName
        regViewController?.lastNameToEdit = userList[indexInDb - 1].lastName
        regViewController?.countryToEdit = userList[indexInDb - 1].country
        regViewController?.emailToEdit = userList[indexInDb - 1].email
        regViewController?.passwordToEdit = userList[indexInDb - 1].password
        regViewController?.editIdentifier = 1
        regViewController?.emailIdToChange = mainEmail
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any)
    {
        if tableView.indexPathsForSelectedRows != nil
        {
            let indexPath = tableView.indexPathForSelectedRow
            let cell = tableView.cellForRow(at: indexPath!)!
            let stringFromTable = cell.textLabel!.text
        
            let emailString = stringFromTable?.components(separatedBy: "(").last?.components(separatedBy: ")").first
            if mainEmail != emailString
            {
                deleteInDatabase(email: emailString!)
                rowCount -= 1
                if indexInDb != 1 && indexInDb > indexPath!.row + 1
                {
                    indexInDb -= 1
                }
                tableView.reloadData()
            }
            else
            {
                let ac = UIAlertController(title: "Delete user", message: "Cannot delete main account", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                ac.addAction(okAction)
                self.present(ac, animated: true)
            }
        }
        else
        {
            let ac = UIAlertController(title: "Delete user", message: "You should choose user", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            ac.addAction(okAction)
            self.present(ac, animated: true)
        }
    }
    
    @IBAction func getInfoButtonTapped(_ sender: Any)
    {
        if tableView.indexPathsForSelectedRows != nil
        {
            let indexPath = tableView.indexPathForSelectedRow
            let cell = tableView.cellForRow(at: indexPath!)!
            let stringFromTable = cell.textLabel!.text
            let emailString = stringFromTable?.components(separatedBy: "(").last?.components(separatedBy: ")").first
        
            let accViewController = storyboard?.instantiateViewController(identifier: "AccVC") as? AccountViewController
            navigationController?.pushViewController(accViewController!, animated: false)
            accViewController?.email = emailString
        }
        else
        {
            let ac = UIAlertController(title: "Get more info", message: "You should choose user", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            ac.addAction(okAction)
            self.present(ac, animated: true)
        }
    }
    
    @IBAction func createButtonTapped(_ sender: Any)
    {
        let regViewController = storyboard?.instantiateViewController(identifier: "RegVC") as? RegistrationViewController
        navigationController?.pushViewController(regViewController!, animated: false)
        
        regViewController?.editIdentifier = 2
        regViewController?.indexInDbToHold = indexInDb
    }
}
