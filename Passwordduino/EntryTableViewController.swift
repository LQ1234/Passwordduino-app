//
//  EntryTableViewController.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class EntryTableViewController: UITableViewController,UISearchBarDelegate {
    var currentlyEditing:EntryTableViewCell?;

    var entries:[Entry]=[];
    var entriesFiltered:[Entry]=[];
    
    var entryTypeSymbols:[EntryType:UIImage]=[:];
    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad();
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
        loadEntryTypeSymbols();
        searchBar.delegate = self
        loadEntries()
        
        entriesFiltered = entries

    }
    override func viewDidAppear(_ animated: Bool) {
        disableRearrangingFunctionsIfNeeded();
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entriesFiltered.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)as! EntryTableViewCell;
        let cellcontents=entriesFiltered[indexPath.row];
        cell.entryLabel.text=cellcontents.name;
        cell.entryTypeImage.image=entryTypeSymbols[cellcontents.entryType];
        cell.viewController=self;
        cell.entry=cellcontents;
        return cell;
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView.isEditing {
            return true;
        }
        return false;
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            assertNotSearching();
            let entry = entries[indexPath.row];
            if(entry.entryType == .password){
                deleteUserPassword(name: entry.name)
            }
            entries.remove(at: indexPath.row);
            entriesFiltered.remove(at: indexPath.row);

            tableView.deleteRows(at: [indexPath], with: .fade);
            saveEntries();

        } else if editingStyle == .insert {
        }    
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        assertNotSearching();
        let element = entries.remove(at: fromIndexPath.row)
        entries.insert(element, at: to.row)
        
        entriesFiltered.remove(at: fromIndexPath.row)
        entriesFiltered.insert(element, at: to.row)
        saveEntries();

    }
    

    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated);
        switch(editing){
        case true:disableSearchFunction();
        case false:enableSearchFunction();
        }
    }
    // MARK: Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        entriesFiltered = searchText.isEmpty ? entries : entries.filter { (entry: Entry) -> Bool in
            return entry.name.lowercased().contains(searchText.lowercased());
        }
        
        tableView.reloadData()
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar){
        disableRearrangingFunctions();

    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar){
        if(searchBar.text?.isEmpty ?? true){
            enableRearrangingFunctions();
        }
    }
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool{
        return(true);
    }
    func searchBarSearchButtonClicked(_ searchBar:UISearchBar){
        searchBar.resignFirstResponder();
    }
    func searchBarCancelButtonClicked(_ searchBar:UISearchBar){
        searchBar.resignFirstResponder();
    }
    
    
    private func disableRearrangingFunctions(){
        navigationController?.setNavigationBarHidden(true, animated: true)

    }
    private func enableRearrangingFunctions(){
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    private func disableSearchFunction(){
        searchBar.isUserInteractionEnabled=false;
    }
    private func enableSearchFunction(){
        searchBar.isUserInteractionEnabled=true;

    }
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.setNavigationBarHidden(false, animated: true)

        if let nav=segue.destination as? UINavigationController{
            if let dest=nav.topViewController as?PasswordOrDuckyViewController{
                dest.rootView=self;
            }
        }
        if let entry=currentlyEditing?.entry{

            if let vc=segue.destination as? PasswordViewController{
                vc.entry=entry;
            }
            if let vc=segue.destination as? DuckyViewController{
                vc.entry=entry;
            }
        }
    }
    @IBAction func unwindToEntryList(sender: UIStoryboardSegue) {
        disableRearrangingFunctionsIfNeeded();
        var resultEntry:Entry?;
        if let sourceViewController = sender.source as? PasswordViewController, let entry = sourceViewController.entry {
            resultEntry=entry;
        }
        if let sourceViewController = sender.source as? DuckyViewController, let entry = sourceViewController.entry {
            resultEntry=entry;
        }
        if let resultEntry=resultEntry{
            if let currentlyEditing=currentlyEditing, let indx=tableView.indexPath(for:currentlyEditing){

                let oldVal=entriesFiltered[indx.row];
                entries[entries.firstIndex{$0 === oldVal}!]=resultEntry;
                entriesFiltered[indx.row]=resultEntry;
                tableView.reloadRows(at: [indx], with: .none)
                
            }else{
                addNewEntry(entry: resultEntry)
            }
        }
        currentlyEditing=nil;
        saveEntries();
    }
    //MARK: Entry Util
    private func disableRearrangingFunctionsIfNeeded(){
        if((searchBar.text?.isEmpty ?? false)){
            enableRearrangingFunctions();
        }else{
            disableRearrangingFunctions();
        }
    }
    private func loadEntryTypeSymbols(){
        let duck = UIImage(named: "DuckSymbol")
        let key = UIImage(named: "KeySymbol")
        entryTypeSymbols[.password]=key;
        entryTypeSymbols[.ducky]=duck;
    }

    
    @discardableResult func addNewEntry(entry:Entry)->Int{
        let newIndex=entries.count;
        
        entries.insert(entry,at:newIndex);
        entriesFiltered.insert(entry,at:newIndex);
        tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
        return(newIndex);
    }
    
    func editAndAddNewEntry(entryType:EntryType){
        switch(entryType){
            case .password:performSegue(withIdentifier: "editPasswordNewNavSegue", sender: self);
            case .ducky:performSegue(withIdentifier: "editDuckyNewNavSegue", sender: self);
        }
    }
    
    private func assertNotSearching(){
        precondition(searchBar.text?.isEmpty ?? true, "Searching when not expected, terminating")
    }
    private func saveEntries() {
        guard let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: entries, requiringSecureCoding: false) else{
            infoPrompt(title:"Error",message:"Error serializing entries to file, report to developer.",controller: self){ (_) in};
            return;
        }
        guard ((try? archivedData.write(to: Entry.archiveURL)) != nil) else{
            infoPrompt(title:"Error",message:"Error writing entries to file",controller: self){ (_) in };
            return;
        }
 
    }
    @discardableResult private func loadEntries() -> Bool{
        guard let archivedData = try? Data(contentsOf: Entry.archiveURL) else {
            return false;
        }
        guard let entries = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedData) as? [Entry] else{
            infoPrompt(title:"Error",message:"Error deserializing entries from file, report to developer.",controller: self){ (_) in};
            return(false);
        }
        self.entries=entries;
        return true;
    }
}
