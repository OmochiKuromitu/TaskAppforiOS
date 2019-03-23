import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController , UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let realm = try! Realm()
    var task: Task!
    
    // カテゴリ一覧
    let categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "name", ascending: true)
    // カテゴリ選択用ピッカー
    let categoryPicker = UIPickerView()
    // 選択中のカテゴリ
    var selectedCategory: Category?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //背景をタップしたらdismissKeyboardメソッドを呼ぶ様に設定
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        // 設定
        selectedCategory = task.category
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        
        // カテゴリ一覧のpicker作成
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.showsSelectionIndicator = true
        categoryTextField.inputView = categoryPicker
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ピッカーリロード
        categoryPicker.reloadAllComponents()
        // ピッカーの選択位置とcategoryTextFieldの表示設定
        categoryPicker.selectRow(0, inComponent: 0, animated: false)
        categoryTextField.text = "(設定なし)"
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // 画面戻る時でかつタイトルが入力されているときのみ登録
        if isMovingFromParent && self.titleTextField.text != "" {
            // 画面から離れる時に保存
            try! realm.write {
                self.task.category = selectedCategory
                self.task.title = self.titleTextField.text!
                self.task.contents = self.contentsTextView.text
                self.task.date = self.datePicker.date
                self.realm.add(self.task, update: true)
            }
            
            setNotification(task: task)
        }
        super.viewWillDisappear(animated)
        
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            // 「設定なし」表示
            return "(設定なし)"
        } else {
            // カテゴリ名表示
            return categoryArray[row - 1].name
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextField.endEditing(true)
        
        let row = categoryPicker.selectedRow(inComponent: 0)
        if row == 0 {
            selectedCategory = nil
            categoryTextField.text = "(設定なし)"
        } else {
            selectedCategory = categoryArray[row - 1]
            categoryTextField.text = selectedCategory!.name
        }
    }
    
    // UIPickerViewDataSourceその1
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerViewDataSourceその2
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count + 1
    }
    
    //タスクのローカル通知を登録
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default
        
        //ローカル通知が発動するtriggerを作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponents, repeats: false)
        
        //ローカル通知を作成
        let request = UNNotificationRequest.init(identifier: String(task.id), content: content, trigger: trigger)
        
        //ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) {
            (error) in
            print(error ?? "ローカル通知登録　OK")
        }
        
        //未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/-------------")
                print(request)
                print("/-------------")
            }
        }
        
    }
    

}
