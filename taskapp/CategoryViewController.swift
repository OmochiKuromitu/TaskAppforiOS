import UIKit
import RealmSwift

class CategoryViewController: UIViewController {

    let realm = try! Realm()
    
    @IBOutlet weak var addCategoryButton: UIButton!
    @IBOutlet weak var textCt: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        //最初は登録ボタンを非活性化
        addCategoryButton.isEnabled = false
        
    }
    
    @IBAction func isEnabeleAddButton(_ sender: Any) {
        
        // データが入力されてるときだけ登録ボタンを活性化
        if (textCt.text == ""){
            addCategoryButton.isEnabled = false
        }else{
            addCategoryButton.isEnabled = true
        }
    }
    
    // 登録ボタンを押下した時の処理
    @IBAction func addCt(_ sender: Any) {
        
        // カテゴリクラス初期化
        let category = Category()
        
        // カテゴリクラスのnameにテキストを入力
        category.name = textCt.text!
        
        // ここからrealmに登録
        let allCategories = realm.objects(Category.self)
        if allCategories.count != 0 {
            category.id = allCategories.max(ofProperty: "id")! + 1
        }
        try! realm.write {
            self.realm.add(category, update: true)
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    //登録をキャンセルして戻る
    @IBAction func cancelCategoryView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
