import UIKit
import SQLite3

class ViewController: UIViewController
{
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpElements()
    }
    
    func readFromDatabase()
    {
        var count: Int = 0, indexInDb: Int = 0
        var db, stmt: OpaquePointer?
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK
        {
            print("Error opening database")
            return
        }
        
        let queryString = "SELECT * FROM Users"
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK
        {
            print("Error preparing query")
            return
        }
        
        let authViewController = storyboard?.instantiateViewController(identifier: "AuthVC") as? AuthorizationViewController
        while (sqlite3_step(stmt) == SQLITE_ROW)
        {
            indexInDb += 1
            if emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == String(cString: sqlite3_column_text(stmt, 4)) &&
               passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == String(cString: sqlite3_column_text(stmt, 5))
            {
                count += 1

                navigationController?.pushViewController(authViewController!, animated: false)
                authViewController?.indexInDb = indexInDb
            }
        }
        authViewController?.rowCount = indexInDb
        
        sqlite3_finalize(stmt)
        sqlite3_close_v2(db)
        
        if count == 0
        {
            errorLabel.text = "Wrong email or password"
            errorLabel.alpha = 1
        }
    }
    
    func setUpElements()
    {
        errorLabel.alpha = 0
        
        loginButton.layer.borderWidth = 1.5
        loginButton.layer.cornerRadius = 20
        signUpButton.layer.borderWidth = 1.5
        signUpButton.layer.cornerRadius = 20
        
        setUpTextField(emailTextField)
        setUpTextField(passwordTextField)
    }
    
    func setUpTextField(_ textFieldName: UITextField)
    {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: textFieldName.frame.size.height-7.5, width: textFieldName.frame.size.width, height: 1.5)
        bottomLine.backgroundColor = UIColor.black.cgColor
        textFieldName.borderStyle = UITextField.BorderStyle.none
        textFieldName.layer.addSublayer(bottomLine)
    }

    func validateFields() -> String?
    {
        if emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == ""
        {
            return "Please, fill in all fields"
        }
        
        return nil
    }
    
    @IBAction func loginButtonTapped(_ sender: Any)
    {
        let error = validateFields()
        
        if error != nil
        {
            showError(error!)
        }
        else
        {
            readFromDatabase()
        }
        passwordTextField.text = ""
    }
    
    func showError(_ message: String)
    {
        errorLabel.text = message
        errorLabel.alpha = 1
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any)
    {
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    //Delete word "back" in navigation bar on RegistrationViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
}

