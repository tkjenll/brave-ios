// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import Shared
import SwiftKeychainWrapper

private let log = Logger.browserLogger

class LoginInfoViewController: LoginAuthViewController {
    
    // MARK: UX
    
    struct UX {
        static let informationRowHeight: CGFloat = 58
        static let createdRowHeight: CGFloat = 66
        static let standardItemHeight: CGFloat = 44
    }
    
    // MARK: Section
    
    enum Section: Int, CaseIterable {
        case information
        case createdDate
        case delete
    }
    
    // MARK: ItemType
    
    enum InfoItem: Int, CaseIterable {
        case websiteItem
        case usernameItem
        case passwordItem
    }
    
    // MARK: Private
    
    private let profile: Profile
    private weak var websiteField: UITextField?
    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?
    
    private var loginEntry: Login {
        didSet {
            tableView.reloadData()
        }
    }
    private var isEditingFieldData: Bool = false {
        didSet {
            if isEditingFieldData != oldValue {
                tableView.reloadData()
            }
        }
    }
    
    private var formattedCreationDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(loginEntry.timeCreated / 1_000_000))
        let dateFormatter = DateFormatter().then {
            $0.locale = .current
            $0.dateFormat = "EEEE, MMM d, yyyy"
        }

        return dateFormatter.string(from: date)
    }
    
    // MARK: Lifecycle

    init(profile: Profile, loginEntry: Login) {
        self.loginEntry = loginEntry
        self.profile = profile
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.do {
            $0.title = URL(string: loginEntry.hostname)?.baseDomain ?? ""
            $0.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        }

        tableView.do {
            $0.accessibilityIdentifier = "Login Details"
            $0.register(CenteredButtonCell.self)
            $0.register(LoginInfoTableViewCell.self)
            $0.registerHeaderFooter(SettingsTableSectionHeaderFooterView.self)
            $0.tableFooterView = SettingsTableSectionHeaderFooterView(
                frame: CGRect(width: tableView.bounds.width, height: 1.0))
            $0.estimatedRowHeight = 44.0
        }
    }
}

// MARK: TableViewDataSource - TableViewDelegate

extension LoginInfoViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooter() as SettingsTableSectionHeaderFooterView
        headerView.titleLabel.text = "LOGIN DETAILS"
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == Section.information.rawValue ? UX.standardItemHeight : 1.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case Section.information.rawValue:
                switch indexPath.row {
                    case InfoItem.websiteItem.rawValue:
                        let cell = tableView.dequeueReusableCell(for: indexPath) as LoginInfoTableViewCell
                        
                        cell.do {
                            $0.delegate = self
                            $0.highlightedLabel.text = "Website"
                            $0.descriptionTextField.text = loginEntry.hostname
                            $0.isEditingFieldData = false
                            $0.tag = InfoItem.websiteItem.rawValue
                        }
                        
                        websiteField = cell.descriptionTextField
                        websiteField?.accessibilityIdentifier = "websiteField"
                        
                        cell.contentView.alpha = isEditingFieldData ? 0.5 : 1.0
                        
                        return cell
                    case InfoItem.usernameItem.rawValue:
                        let cell = tableView.dequeueReusableCell(for: indexPath) as LoginInfoTableViewCell
                      
                        cell.do {
                            $0.delegate = self
                            $0.highlightedLabel.text = "Username"
                            $0.descriptionTextField.text = loginEntry.username
                            $0.descriptionTextField.keyboardType = .emailAddress
                            $0.descriptionTextField.returnKeyType = .next
                            $0.isEditingFieldData = isEditingFieldData
                            $0.tag = InfoItem.usernameItem.rawValue
                        }
                        
                        usernameField = cell.descriptionTextField
                        usernameField?.accessibilityIdentifier = "usernameField"
                        
                        return cell
                    case InfoItem.passwordItem.rawValue:
                        let cell = tableView.dequeueReusableCell(for: indexPath) as LoginInfoTableViewCell
                      
                        cell.do {
                            $0.delegate = self
                            $0.highlightedLabel.text = "Password"
                            $0.descriptionTextField.text = loginEntry.password
                            $0.descriptionTextField.returnKeyType = .done
                            $0.displayDescriptionAsPassword = true
                            $0.isEditingFieldData = isEditingFieldData
                            $0.tag = InfoItem.passwordItem.rawValue
                        }
                        
                        passwordField = cell.descriptionTextField
                        passwordField?.accessibilityIdentifier = "passwordField"
                        
                        return cell
                    default:
                        fatalError("No cell available for index path: \(indexPath)")
                }
            case Section.createdDate.rawValue:
                let cell = tableView.dequeueReusableCell(for: indexPath) as CenteredButtonCell
            
                cell.do {
                    $0.textLabel?.text = "Created \(formattedCreationDate)"
                    $0.tintColor = .secondaryBraveLabel
                    $0.selectionStyle = .none
                    $0.backgroundColor = .secondaryBraveBackground
                }
                return cell
            case Section.delete.rawValue:
                let cell = tableView.dequeueReusableCell(for: indexPath) as CenteredButtonCell
                cell.do {
                    $0.textLabel?.text = "Delete"
                    $0.tintColor = .braveOrange
                }
                return cell
            default:
                fatalError("No cell available for index path: \(indexPath)")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case Section.information.rawValue:
                return InfoItem.allCases.count
            default:
                return 1
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
            case Section.information.rawValue:
                return UX.informationRowHeight
            case Section.createdDate.rawValue:
                return UX.createdRowHeight
            case Section.delete.rawValue:
                return UX.standardItemHeight
            default:
                return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
            case Section.delete.rawValue:
                deleteLogin()
            default:
                if !isEditingFieldData {
                    showActionMenu(for: indexPath)
                }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: Actions

extension LoginInfoViewController {
    
    @objc private func edit() {
        isEditingFieldData = true
        
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEditing))

        cellForItem(InfoItem.usernameItem)?.descriptionTextField.becomeFirstResponder()
    }
    
    private func showActionMenu(for indexPath: IndexPath) {
        if indexPath.section == Section.createdDate.rawValue || indexPath.row == Section.delete.rawValue {
            return
        }

        guard let cell = tableView.cellForRow(at: indexPath) as? LoginInfoTableViewCell else {
            return
        }
        cell.becomeFirstResponder()
        
        UIMenuController.shared.showMenu(from: tableView, rect: cell.frame)
    }
    
    @objc private func doneEditing() {
        isEditingFieldData = false
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        
        tableView.reloadData()
    }
    
    private func deleteLogin() {

    }
    
    private func cellForItem(_ infoItem: InfoItem) -> LoginInfoTableViewCell? {
        guard let cell = tableView.cellForRow(at: IndexPath(row: infoItem.rawValue, section: 0)) as? LoginInfoTableViewCell else {
            return nil
        }
    
        return cell
    }
}

// MARK: LoginInfoTableViewCellDelegate

extension LoginInfoViewController: LoginInfoTableViewCellDelegate {
    func shouldReturnAfterEditingTextField(_ cell: LoginInfoTableViewCell) -> Bool {
        switch cell.tag {
            case InfoItem.usernameItem.rawValue:
                cellForItem(InfoItem.passwordItem)?.descriptionTextField.becomeFirstResponder()
                return false
            case InfoItem.passwordItem.rawValue:
                doneEditing()
                return true
            default:
                return true
        }
    }
    
    func canPerform(action: Selector, for cell: LoginInfoTableViewCell) -> Bool {
        return false
    }
    
    func didSelectOpenAndFill(_ cell: LoginInfoTableViewCell) {
        
    }
    
    func textFieldDidEndEditing(_ cell: LoginInfoTableViewCell) {
        if cell.tag == InfoItem.passwordItem.rawValue {
            cell.displayDescriptionAsPassword = true
        }
    }
}

