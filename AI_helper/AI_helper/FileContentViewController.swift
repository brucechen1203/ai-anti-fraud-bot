import UIKit

class FileContentViewController: UIViewController {
    @IBOutlet weak var mfileContentTextView: UITextView!
    
    var fileContent: String? // 變數用來接收數據

    override func viewDidLoad() {
        super.viewDidLoad()
        // 將 TextView 設為不可輸入
        mfileContentTextView.isEditable = false
        mfileContentTextView.isSelectable = false
        
        // 顯示傳入的檔案內容
        if let content = fileContent {
            // 解析 JSON
            if let jsonData = content.data(using: .utf8) {
                do {
                    // 將 JSON 轉換成字典
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let extractedContent = jsonObject["content"] as? String {
                        // 把解析完的內容放到TextView內
                        mfileContentTextView.text = extractedContent
                    }
                } catch {
                    print("解析 JSON 時發生錯誤: \(error)")
                }
            }
        }
    }
}
