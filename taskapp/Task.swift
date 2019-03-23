import RealmSwift

class Task: Object {
    //管理用ID。プライマリーキー
    @objc dynamic var id = 0
    
    //カテゴリー
    @objc dynamic var category: Category?
    
    //タイトル
    @objc dynamic var title = ""

    //内容
    @objc dynamic var contents = ""
    
    //日時
    @objc dynamic var date = Date()
    
    // IDをプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
