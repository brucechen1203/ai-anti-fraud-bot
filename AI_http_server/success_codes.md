# Server
- 1 已經能接收app上傳的錄音檔
    ```
    from flask import Flask, request
    import os

    app = Flask(__name__)

    # 設定上傳的錄音檔保存路徑
    UPLOAD_FOLDER = 'uploads'
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # 確保目錄存在
    app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

    @app.route('/upload', methods=['POST'])
    def upload_file():
        if 'file' not in request.files:
            return 'No file part', 400
        file = request.files['file']
        if file.filename == '':
            return 'No selected file', 400
        if file:
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
            file.save(file_path)  # 保存檔案
            return 'File uploaded successfully', 200

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=12345)  # 在所有網路介面上運行伺服器
    ```

# App
- 1 能上傳錄音檔到Server
    ```
    //
    //  ViewController.swift
    //  AI_helper
    //
    //  
    //

    import UIKit
    import UniformTypeIdentifiers

    class ViewController: UIViewController {

        @IBOutlet weak var mUploadBtn: UIButton!
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
        }
        @IBAction func mUploadBtn_down(_ sender: UIButton) {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
                    documentPicker.delegate = self
                    documentPicker.modalPresentationStyle = .formSheet
                    present(documentPicker, animated: true, completion: nil)
        }
        private func uploadFile(url: URL) {
                var request = URLRequest(url: URL(string: "http://localhost:12345/upload")!) // 替換為你的伺服器 URL
                request.httpMethod = "POST"
                
                let boundary = UUID().uuidString
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                let body = NSMutableData()
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(url.lastPathComponent)\"\r\n")
                body.appendString("Content-Type: audio/m4a\r\n\r\n") // 根據你的音頻格式調整
                body.append(try! Data(contentsOf: url))
                body.appendString("\r\n")
                body.appendString("--\(boundary)--\r\n")
                
                request.httpBody = body as Data
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    }
                    if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                        print("Upload successful!")
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
            uploadFile(url: url) // 在這裡調用上傳檔案的方法
        }
    }

    // 擴展 NSMutableData
    extension NSMutableData {
        func appendString(_ string: String) {
            let data = string.data(using: String.Encoding.utf8)!
            append(data)
        }
    }
    ```
