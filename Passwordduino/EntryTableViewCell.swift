//
//  EntryTableViewCell.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class EntryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var entryTypeImage: UIImageView!
    @IBOutlet weak var entryLabel: UILabel!
    weak var viewController: EntryTableViewController!
    weak var entry:Entry!;
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
    }
    @IBAction func editButtonClicked(_ sender: Any) {
        viewController.currentlyEditing=self
        
        switch(entry.entryType){
            case .password:viewController.performSegue(withIdentifier: "editPasswordSegue", sender: viewController);
            case .ducky:viewController.performSegue(withIdentifier: "editDuckySegue", sender: viewController);
        }
    }
    
    @IBAction func executeButtonPressed(_ sender: UIButton) {
        /*
        let data="What is Lorem Ipsum? Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum. Why do we use it? It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like). Where does it come from? Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of \"de Finibus Bonorum et Malorum\" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, \"Lorem ipsum dolor sit amet..\", comes from a line in section 1.10.32. The standard chunk of Lorem Ipsum used since the 1500s is reproduced below for those interested. Sections 1.10.32 and 1.10.33 from \"de Finibus Bonorum et Malorum\" by Cicero are also reproduced in their exact original form, accompanied by English versions from the 1914 translation by H. Rackham. Where can I get some? There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc.".data(using:.ascii)!;
        let data2="testing 1 2 3 4".data(using:.ascii)!;
        let data3="What is Lorem Ipsum? Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more r".data(using:.ascii)!;
        let data4="What is Lorem Ipsum? Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer to".data(using:.ascii)!;
        var curr="testing";*/
        let duckyScript =
"""
command space
string google chrome
delay 100
enter
delay 100
command t
string https://www.youtube.com/watch?v=Ob33Db1_h90
delay 100
enter
"""
        Bytecode.from(ducky: duckyScript, passwordInfo: (entries:viewController.entries, controller: viewController)) { (res, error) in
            guard let res=res else{
                print("Error: \(error)")
                return;
            }
            print("parsed bytecode");
            bluetoothWrapper.selectedPasswordduino?.sendEncrypted(data: res, callback: { (error) in
                print("send result: \(error)")
            })
        }

        /*
        func test(){
            print("sending")

            let dat=(curr+String(curr.count)).data(using:.ascii)!;
            bluetoothWrapper.selectedPasswordduino?.send(data: dat, callback: { (error) in
                print("result: \(error)")
                if((error) == nil){
                    curr+=" test";
                    test();
                }
            })
        }
         */
    }
    
}
