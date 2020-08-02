import UIKit
import SQLite3

class RegistrationViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate
{
    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var choosePhotoButton: UIButton!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    var firstNameToEdit: String!,
        lastNameToEdit: String!,
        countryToEdit: String!,
        emailToEdit: String!,
        passwordToEdit: String!,
        editIdentifier: Int!,
        emailIdToChange: String!,
        indexInDbToHold: Int!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpElements()
        imageView.image = UIImage(named: "no-avatar.jpg")
    }
    
    func writeToDataBase(_ ind: Int)
    {
        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var db, stmt: OpaquePointer?
        var rowCount = 0
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK
        {
            print("Error opening database")
            return
        }
        
        let queryString1 = "SELECT * FROM Users"
        sqlite3_prepare(db, queryString1, -1, &stmt, nil)
        
        while (sqlite3_step(stmt) == SQLITE_ROW)
        {
            if email == String(cString: sqlite3_column_text(stmt, 4))
            {
                errorLabel.text = "User with this email already exists"
                errorLabel.alpha = 1
                sqlite3_finalize(stmt)
                sqlite3_close_v2(db)
                return
            }
        }
        
        let createTableQuery = "CREATE TABLE IF NOT EXISTS Users (id INTEGER PRIMARY KEY, firstName TEXT, lastName TEXT, country TEXT, email TEXT, password TEXT)"
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK
        {
            print("Error creating table")
            return
        }
        
        let insertQuery = "INSERT INTO Users (firstName, lastName, country, email, password) VALUES (?, ?, ?, ?, ?)"
        if sqlite3_prepare(db, insertQuery, -1, &stmt, nil) != SQLITE_OK
        {
            print("Error binding query")
            return
        }
        
        sqlite3_bind_text(stmt, 1, (firstName! as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (lastName! as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (country! as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (email! as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (password! as NSString).utf8String, -1, nil)
        
        sqlite3_step(stmt)
        
        let queryString2 = "SELECT * FROM Users"
        sqlite3_prepare(db, queryString2, -1, &stmt, nil)
        
        while (sqlite3_step(stmt) == SQLITE_ROW)
        {
            rowCount += 1
        }
        
        let authViewController = storyboard?.instantiateViewController(identifier: "AuthVC") as? AuthorizationViewController
        navigationController?.pushViewController(authViewController!, animated: false)
        
        authViewController?.rowCount = rowCount
        
        if ind == 0
        {
            authViewController?.indexInDb = rowCount
        }
        else
        {
            authViewController?.indexInDb = indexInDbToHold
        }
        
        sqlite3_finalize(stmt)
        sqlite3_close_v2(db)
    }
    
    func updateData()
    {
        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var db, stmt: OpaquePointer?
        var rowCount = 0
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        sqlite3_open(fileURL.path, &db)
        
        let queryString1 = "SELECT * FROM Users"
        sqlite3_prepare(db, queryString1, -1, &stmt, nil)
        
        while (sqlite3_step(stmt) == SQLITE_ROW)
        {
            if email == String(cString: sqlite3_column_text(stmt, 4)) && email != emailIdToChange
            {
                errorLabel.text = "User with this email already exists"
                errorLabel.alpha = 1
                sqlite3_finalize(stmt)
                sqlite3_close_v2(db)
                return
            }
        }
        
        let updateStatementString = "UPDATE Users SET firstName = '\(firstName!)', lastName = '\(lastName!)', country = '\(country!)', email = '\(email!)', password = '\(password!)' WHERE email LIKE '\(emailIdToChange!)'"
        
        sqlite3_prepare_v2(db, updateStatementString, -1, &stmt, nil)
        sqlite3_step(stmt)
        
        let queryString2 = "SELECT * FROM Users"
        sqlite3_prepare(db, queryString2, -1, &stmt, nil)
        
        let authViewController = storyboard?.instantiateViewController(identifier: "AuthVC") as? AuthorizationViewController
        navigationController?.pushViewController(authViewController!, animated: false)
        
        while (sqlite3_step(stmt) == SQLITE_ROW)
        {
            rowCount += 1
            if String(cString: sqlite3_column_text(stmt, 4)) == email
            {
                authViewController?.indexInDb = rowCount
            }
        }
        authViewController?.rowCount = rowCount
        
        sqlite3_finalize(stmt)
        sqlite3_close_v2(db)
    }
    
    func setUpElements()
    {
        errorLabel.alpha = 0
        
        choosePhotoButton.layer.borderWidth = 1.5
        choosePhotoButton.layer.cornerRadius = 20
        signUpButton.layer.borderWidth = 1.5
        signUpButton.layer.cornerRadius = 20
        
        setUpTextField(firstNameTextField)
        setUpTextField(lastNameTextField)
        setUpTextField(countryTextField)
        setUpTextField(emailTextField)
        setUpTextField(passwordTextField)
        setUpTextField(confirmPasswordTextField)
        
        firstNameTextField.text = firstNameToEdit
        lastNameTextField.text = lastNameToEdit
        countryTextField.text = countryToEdit
        emailTextField.text = emailToEdit
        passwordTextField.text = passwordToEdit
        
        if editIdentifier == 1
        {
            signUpButton.setTitle("Edit", for: .normal)
        }
        else if editIdentifier == 2
        {
            signUpButton.setTitle("Create", for: .normal)
        }
    }
    
    func setUpTextField(_ textFieldName: UITextField)
    {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: textFieldName.frame.size.height-7.5, width: textFieldName.frame.size.width, height: 1.5)
        bottomLine.backgroundColor = UIColor.black.cgColor
        textFieldName.borderStyle = UITextField.BorderStyle.none
        textFieldName.layer.addSublayer(bottomLine)
    }
    
    @IBAction func choosePhotoButtonTapped(_ sender: Any)
    {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imageView.image = image
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func validateFields() -> String?
    {
        if  firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == ""
        {
            return "Please, fill in all fields"
        }
        
        if passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).count < 8
        {
            return "Your password is less then 8 characters"
        }
        else if confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        {
            return "Wrong password confirmation"
        }
        
        if emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).contains("@") &&
            emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).contains(".")
        {
            return nil
        }
        else
        {
            return "Incorrect email format"
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any)
    {
        let error = validateFields()
        
        if error != nil
        {
            showError(error!)
        }
        else if signUpButton.titleLabel?.text == "Sign Up"
        {
            writeToDataBase(0)
        }
        else if signUpButton.titleLabel?.text == "Edit"
        {
            updateData()
        }
        else if signUpButton.titleLabel?.text == "Create"
        {
            writeToDataBase(1)
        }
    }
    
    func showError(_ message: String)
    {
        errorLabel.text = message
        errorLabel.alpha = 1
    }
}
