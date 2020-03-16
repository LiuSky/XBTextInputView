//
//  ViewController.swift
//  XBTextInputView
//
//  Created by LiuSky on 03/13/2020.
//  Copyright (c) 2020 LiuSky. All rights reserved.
//

import UIKit
import XBTextInputView

/// MARK - Demo 集合控制器
final class ViewController: UIViewController {

    /// 列表
    private lazy var tableView: UITableView = {
        $0.dataSource = self
        $0.delegate = self
        $0.rowHeight = 50
        $0.tableFooterView = UIView()
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UITableView())
    
    /// 数组
    private let array = [("默认", FormatterType.default),
                         ("手机号码", FormatterType.phoneNumber),
                         ("中文", FormatterType.chinese),
                         ("身份证", FormatterType.idCard),
                         ("数字", FormatterType.number),
                         ("字母", FormatterType.alphabet),
                         ("数字和字母", FormatterType.numberAndAlphabet),
                         ("自定义 -> 中文数字字母", FormatterType.custom(regexString: "^[\\u4E00-\\u9FA5A-Za-z0-9]+$"))]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Demo"
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

/// MARK - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")!
        cell.textLabel?.text = array[indexPath.row].0
        return cell
    }
}

/// MARK - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = DemoViewController()
        vc.navigationItem.title = array[indexPath.row].0
        vc.formatterType = array[indexPath.row].1
        navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
        
//        let vc = TextViewDemoViewController()
//        navigationController?.pushViewController(vc, animated: true)
    }
}

