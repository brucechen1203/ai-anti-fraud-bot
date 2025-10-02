//
//  ViewController.swift
//  AI_helper
//
//  
//

import UIKit
import UniformTypeIdentifiers
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    @IBOutlet weak var mUploadBtn: UIButton!
    @IBOutlet weak var mNextPageBtn: UIButton!
    @IBOutlet weak var mPrevPageBtn: UIButton!
    @IBOutlet weak var mLabel1: UILabel!
    @IBOutlet weak var mLabel2: UILabel!
    @IBOutlet weak var mLabel3: UILabel!
    @IBOutlet weak var mLabel4: UILabel!
    @IBOutlet weak var mLabel5: UILabel!
    @IBOutlet weak var mLabel6: UILabel!
    @IBOutlet weak var mLabel7: UILabel!
    @IBOutlet weak var mLabel8: UILabel!
    @IBOutlet weak var mLabel1_risk: UILabel!
    @IBOutlet weak var mLabel2_risk: UILabel!
    @IBOutlet weak var mLabel3_risk: UILabel!
    @IBOutlet weak var mLabel4_risk: UILabel!
    @IBOutlet weak var mLabel5_risk: UILabel!
    @IBOutlet weak var mLabel6_risk: UILabel!
    @IBOutlet weak var mLabel7_risk: UILabel!
    @IBOutlet weak var mLabel8_risk: UILabel!
    @IBOutlet weak var mResultBtn1: UIButton!
    @IBOutlet weak var mResultBtn2: UIButton!
    @IBOutlet weak var mResultBtn3: UIButton!
    @IBOutlet weak var mResultBtn4: UIButton!
    @IBOutlet weak var mResultBtn5: UIButton!
    @IBOutlet weak var mResultBtn6: UIButton!
    @IBOutlet weak var mResultBtn7: UIButton!
    @IBOutlet weak var mResultBtn8: UIButton!
    @IBOutlet weak var mPageNumLabel: UILabel!
    var currentPage = 0
    let itemsPerPage = 8
    // 全域變數，用於存儲文件名
    var fileNames: [String] = []
    // Label,Button 陣列
    var timeLabels: [UILabel] = []
    var riskLabels: [UILabel] = []
    var resultBtns: [UIButton] = []
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW")) // 設置語言
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        // 請求語音識別授權
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied, .restricted, .notDetermined:
                print("Speech recognition not available")
            @unknown default:
                break
            }
        }
        // 初始化 Label, Button, fileNames陣列
        fileNames = [""]
        timeLabels = [mLabel1, mLabel2, mLabel3, mLabel4,
                      mLabel5, mLabel6, mLabel7, mLabel8]
        riskLabels = [mLabel1_risk, mLabel2_risk,
                      mLabel3_risk, mLabel4_risk,
                      mLabel5_risk, mLabel6_risk,
                      mLabel7_risk, mLabel8_risk]
        resultBtns = [mResultBtn1, mResultBtn2,
                      mResultBtn3, mResultBtn4,
                      mResultBtn5, mResultBtn6,
                      mResultBtn7, mResultBtn8]
        mUploadBtn.backgroundColor = UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
        mUploadBtn.layer.cornerRadius = 4 // 設定圓角半徑
        mUploadBtn.layer.masksToBounds = true // 確保子視圖不會超出圓角
        
        fetchFilesInfo()
        //displayCurrentPage() // 測試用(無server時)
    }
    
    // 按下Upload按鈕
    @IBAction func mUploadBtn_down(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }
    
    // 向伺服器請求Replies檔案資訊(數量、檔名)
    func fetchFilesInfo() {
        let url = URL(string: "http://172.20.10.4:12345/get_files_info")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let fileCount = json["file_count"] as? Int,
                       let fetchedFileNames = json["file_names"] as? [String] {
                        print("File count: \(fileCount)")
                        print("File names: \(fetchedFileNames)")
                        
                        // 將獲得的文件名給全域變數
                        self.fileNames = fetchedFileNames
                        
                        DispatchQueue.main.async {
                            // 更新 UI 或其他操作
                            self.displayCurrentPage()
                        }
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
        task.resume()
    }
    
    // 更新頁面顯示
    func displayCurrentPage() {
        // 清空當前 Label 顯示
        for label in timeLabels + riskLabels {
            label.text = ""
            label.backgroundColor = .clear
        }
        for button in resultBtns {
            button.setTitle("", for: .normal)
            button.isHidden = true // 隱藏按鈕，若無內容
            button.removeTarget(nil, action: nil, for: .allEvents) // 清除舊的動作
        }
        // 顯示當前頁碼
        mPageNumLabel.text = String(currentPage + 1)
        // 計算當前頁面要顯示的檔案範圍
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, fileNames.count)
        
        // 更新 Label
        for i in startIndex..<endIndex {
            let indexInPage = i - startIndex
            let fileName = fileNames[i]
            let result = parseFileName(fileName)
            if let formattedTime = result.0, let riskLevel = result.1 {
                // 更新時間 Label
                timeLabels[indexInPage].text = formattedTime
                timeLabels[indexInPage].backgroundColor = UIColor(red: 0.6, green: 0.7, blue: 0.2, alpha: 1.0)
                timeLabels[indexInPage].layer.cornerRadius = 4 // 設定圓角半徑
                timeLabels[indexInPage].layer.masksToBounds = true // 確保子視圖不會超出圓角
                timeLabels[indexInPage].translatesAutoresizingMaskIntoConstraints = false // 啟用 Auto Layout
                timeLabels[indexInPage].widthAnchor.constraint(equalToConstant: 150).isActive = true // 設定固定寬度
                
                // 更新風險等級 Label
                switch riskLevel {
                    case "L": riskLabels[indexInPage].text = "低"
                    case "H": riskLabels[indexInPage].text = "高"
                    default: riskLabels[indexInPage].text = "低"
                }
                riskLabels[indexInPage].textColor = .white
                riskLabels[indexInPage].layer.cornerRadius = 4 // 設定圓角半徑
                riskLabels[indexInPage].layer.masksToBounds = true // 確保子視圖不會超出圓角
                riskLabels[indexInPage].translatesAutoresizingMaskIntoConstraints = false // 啟用 Auto Layout
                riskLabels[indexInPage].widthAnchor.constraint(equalToConstant: 30).isActive = true // 設定固定寬度
                riskLabels[indexInPage].backgroundColor = colorForRiskLevel(riskLevel)
                
                // 更新對應的按鈕
                resultBtns[indexInPage].setTitle("分析結果", for: .normal)
                resultBtns[indexInPage].backgroundColor = UIColor(red: 0.6, green: 0.7, blue: 0.2, alpha: 1.0)
                resultBtns[indexInPage].layer.cornerRadius = 4 // 設定圓角半徑
                resultBtns[indexInPage].layer.masksToBounds = true // 確保子視圖不會超出圓角
                resultBtns[indexInPage].translatesAutoresizingMaskIntoConstraints = false // 啟用 Auto Layout
                resultBtns[indexInPage].widthAnchor.constraint(equalToConstant: 94).isActive = true // 設定固定寬度
                resultBtns[indexInPage].isHidden = false // 顯示按鈕
                resultBtns[indexInPage].addTarget(self, action: #selector(didTapResultButton(_:)), for: .touchUpInside)
                resultBtns[indexInPage].tag = i // 使用 tag 來標記對應的文件索引
            } else {
                // 處理 formattedTime 或 riskLevel 為 nil 的情況
                timeLabels[indexInPage].text = "Err"
                riskLabels[indexInPage].text = "Err"
                riskLabels[indexInPage].backgroundColor = .clear // 或其他顏色
            }
        }
    }
    
    // 按下分析結果按鈕
    @objc func didTapResultButton(_ sender: UIButton) {
        let fileIndex = sender.tag // 獲取對應文件的索引
        let fileName = fileNames[fileIndex]
        
        // 取得檔案內容
        fetchFileContent(for: fileName) { [weak self] content in
            DispatchQueue.main.async {
                // 在跳轉之前列印檔案內容
                if let content = content {
                    print("檔案內容:\n\(content)") // 列印內容
                    
                    // 解析 JSON
                    if let jsonData = content.data(using: .utf8) {
                        do {
                            // 將 JSON 轉換成字典
                            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let extractedContent = jsonObject["content"] as? String {
                                // 列印可讀的內容
                                print("可讀的內容:\n\(extractedContent)")
                            }
                        } catch {
                            print("解析 JSON 時發生錯誤: \(error)")
                        }
                    }
                } else {
                    print("無法取得檔案內容")
                }
                
                // 創建下一頁的 viewController
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let fileContentVC = storyboard.instantiateViewController(withIdentifier: "FileContentViewController") as? FileContentViewController {
                    fileContentVC.fileContent = content // 傳遞檔案內容
                    self?.navigationController?.pushViewController(fileContentVC, animated: true)
                }
            }
        }
    }
    
    // 請求response檔案內容
    func fetchFileContent(for fileName: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "http://172.20.10.4:12345/get_file_content/\(fileName)") else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching file content: \(String(describing: error))")
                completion(nil)
                return
            }
            
            // 轉換內容為字串
            let content = String(data: data, encoding: .utf8)
            completion(content)
        }
        task.resume()
    }

    // 解析檔名
    func parseFileName(_ fileName: String) -> (String?, String?) {
        let pattern = "response_(\\d{8})_(\\d{6})_([LMH])\\.txt"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: fileName.utf16.count)
            if let match = regex.firstMatch(in: fileName, options: [], range: range) {
                let datePart = (fileName as NSString).substring(with: match.range(at: 1))
                let timePart = (fileName as NSString).substring(with: match.range(at: 2))
                let riskLevel = (fileName as NSString).substring(with: match.range(at: 3))
                
                let formattedTime = formatDate(date: datePart, time: timePart)
                return (formattedTime, riskLevel)
            }
        }
        return (nil, nil)
    }
    
    // 時間格式
    func formatDate(date: String, time: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        guard let date = dateFormatter.date(from: date + time) else { return nil }
        
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    // 風險等級顏色
    func colorForRiskLevel(_ riskLevel: String) -> UIColor {
        switch riskLevel {
            case "L": return UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)
            case "H": return .red
            default: return .clear
        }
    }
    
    // 上一頁按鈕
    @IBAction func PrevPage(_ sender: UIButton) {
        if currentPage > 0 {
            currentPage -= 1
            displayCurrentPage()
        }
    }
    
    // 下一頁按鈕
    @IBAction func NextPage(_ sender: UIButton) {
        if (currentPage + 1) * itemsPerPage < fileNames.count {
            currentPage += 1
            displayCurrentPage()
        }
    }
    
    // 將錄音轉為文字
    private func convertAudioToText(url: URL, completion: @escaping (String?) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                //completion(recognizedText) // 返回轉換的文本
                
                // 當結果穩定時，才觸發上傳
                if result.isFinal{
                    completion(recognizedText)
                }
            } else {
                completion(nil)
            }
        })
    }
    
    // 將轉換的文字保存為 txt 檔並上傳
    private func uploadTextAsFile(text: String) {
        let fileName = "recognized_text.txt"
        let filePath = NSTemporaryDirectory() + fileName
        do {
            try text.write(toFile: filePath, atomically: true, encoding: .utf8)
            let fileURL = URL(fileURLWithPath: filePath)
            uploadFile(url: fileURL)
        } catch {
            print("Error writing text to file: \(error)")
        }
    }

    // 上傳檔案到伺服器
    private func uploadFile(url: URL) {
        var request = URLRequest(url: URL(string: "http://172.20.10.4:12345/upload")!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(url.lastPathComponent)\"\r\n")
        body.appendString("Content-Type: text/plain\r\n\r\n") // 這裡改為文本格式
        body.append(try! Data(contentsOf: url))
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        request.httpBody = body as Data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            // 成功上傳後輸出成功訊息，並重新抓取伺服器的檔案、刷新頁面
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Upload successful!")
                self.fetchFilesInfo()
            } else {
                print("Upload failed.")
            }
        }
        task.resume()
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // 先將錄音檔轉換為文字
        convertAudioToText(url: url) { [weak self] text in
            if let text = text {
                // 將轉換的文字保存為 txt 檔並上傳
                self?.uploadTextAsFile(text: text)
            } else {
                print("Failed to convert audio to text.")
            }
        }
    }
}

// 擴展 NSMutableData
extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8)!
        append(data)
    }
}
