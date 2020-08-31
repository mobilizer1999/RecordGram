//
//  RecentSearchHIstoryTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/23/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class RecentSearchHistoryTableViewController: UITableViewController {

    let recentSearchCellId = "recentSearchCellId"
    var clearSearchHistoryButton: UIButton! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RecentSearchHistoryCell.self, forCellReuseIdentifier: recentSearchCellId)
        tableView.allowsSelection = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 8
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 35
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 35)
        headerView.backgroundColor = .clear
        headerView.autoresizingMask = .flexibleWidth
        
        let headerTitleLabel = UILabel()
        headerTitleLabel.frame = headerView.bounds
        headerTitleLabel.font = UIFont.systemFont(ofSize: 16)
        headerTitleLabel.textColor = UIColor.gray
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.text = NSLocalizedString("Recent Search History", comment: "Recent search")
        headerTitleLabel.autoresizingMask = .flexibleWidth
        headerView.addSubview(headerTitleLabel)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 35))
        footerView.backgroundColor = .clear
        footerView.autoresizingMask = .flexibleWidth
        
        self.clearSearchHistoryButton = UIButton(type: .custom)
        clearSearchHistoryButton.frame = footerView.bounds
        clearSearchHistoryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        clearSearchHistoryButton.titleLabel?.textAlignment = .center
        clearSearchHistoryButton.setTitleColor(UIColor.gray, for: .normal)
        clearSearchHistoryButton.setTitle(NSLocalizedString("Clear Recent Search History", comment: "Recent search"), for: .normal)
        footerView.addSubview(clearSearchHistoryButton)
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: recentSearchCellId, for: indexPath)
        return cell
    }
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
