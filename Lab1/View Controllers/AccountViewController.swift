import UIKit
import SQLite3

class AccountViewController: UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var firstNameLabel: UILabel!
    
    @IBOutlet weak var lastNameLabel: UILabel!
    
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var countryLabel: UILabel!
    
    var email: String!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        setUpElements()
    }
    
    func setUpElements()
    {
        imageView.image = UIImage(named: "no-avatar.jpg")
        
        var db, stmt: OpaquePointer?
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("UserDatabase.sqlite")
        
        sqlite3_open(fileURL.path, &db)
        
        let queryString = "SELECT * FROM Users WHERE email LIKE '\(email!)'"
        sqlite3_prepare(db, queryString, -1, &stmt, nil)
        sqlite3_step(stmt)
        
        navigationItem.title = String(cString: sqlite3_column_text(stmt, 1))
        firstNameLabel.text = String(cString: sqlite3_column_text(stmt, 1))
        lastNameLabel.text = String(cString: sqlite3_column_text(stmt, 2))
        countryLabel.text = String(cString: sqlite3_column_text(stmt, 3))
        emailLabel.text = String(cString: sqlite3_column_text(stmt, 4))
        
        sqlite3_finalize(stmt)
        sqlite3_close_v2(db)
    }
}
