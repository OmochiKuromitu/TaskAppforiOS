import UIKit
import RealmSwift
import UserNotifications

/*LP1: クラスの承継:UIViewControllerなどのアップル標準のクラスを承継するクラスViewControllerを作成。ViewControllerはUIViewControllerのサブクラス。UIViewControllerはViewControllerのスーパークラス。super.でスーパークラスのプロパティーやメソッドを呼び出す。self.はクラス内でのプロパティーか一時的な変数化を区別するために使う。例えば、self.nameはクラスのプロパティーを示し、nameは一時的な変数を示す。*/

/*LP2: オプショナル型(?!): 変数にnilが入る可能性がある時に使う。 var a: Int? = 10と定義した時にはprint(a!+1)の様に変数に!をつけないとエラーとなる。 var a: Int! = 10 と定義した場合は普通にprint(a+1)の様に変数を呼び出せる。*/
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var categoryTextField: UITextField!
    
    
    //Realmインスタンスを取得
    let realm = try! Realm()
    //DB内のタスクが格納されるリスト：日付順でソート
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    let categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "name", ascending: true)
    
    let categoryPicker = UIPickerView()
    
    var selectedCategory: Category?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
        SearchBar.delegate = self
        
        //カテゴリー一覧のpicker作成
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.showsSelectionIndicator = true
        categoryTextField.inputView = categoryPicker
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text == "" {
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
            tableView.reloadData()
        } else {
        var kensaku = "category = '" + searchBar.text! + "'"
        var categorysearch = realm.objects(Task.self).filter (kensaku)
        taskArray = categorysearch
        print(taskArray)
        tableView.reloadData()
        }
    }

    // MARK: UITableViewのDataSourceプロトコルのメソッド
    // データの数を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }

    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なセルを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            //削除するタスクを取得
            let task = self.taskArray[indexPath.row]
            
            //ローカル通知をキャンセル
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            //データベースから削除
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/--------------")
                    print(request)
                    print("/--------------")
                }
            }
        }
    }
    
    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray [indexPath!.row]
        } else {
            let task = Task()
            task.date = Date()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
            
        }
    }
    
    //入力画面から戻ってきた時にTable Viewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        
        categoryPicker.reloadAllComponents()
        categoryPicker.selectRow(0, inComponent: 0, animated: false)
        
        categoryTextField.text = "(全てのカテゴリー)"
        if let category = selectedCategory {
            for i in 0..<categoryArray.count {
                if categoryArray[i].id == category.id {
                    categoryPicker.selectRow(i + 1, inComponent: 0, animated: false)
                    categoryTextField.text = categoryArray[i].name
                    break
                }
            }
            
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "(全てのカテゴリー)"
        } else {
            return categoryArray[row - 1].name
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextField.endEditing(true)
        
        let row = categoryPicker.selectedRow(inComponent: 0)
        if row == 0 {
            selectedCategory = nil
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
            categoryTextField.text = "(全てのカテゴリー)"
        } else {
            selectedCategory = categoryArray[row - 1]
            let predicate = NSPredicate(format: "category = %@", selectedCategory!)
            taskArray = try! Realm().objects(Task.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
            categoryTextField.text = selectedCategory!.name
        }
        tableView.reloadData()
    }
    
    
}

