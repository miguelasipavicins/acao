/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    //new part
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //MARK: Verifica se usuário já fez login
    override func viewDidLoad() {
        FIRAuth.auth()!.addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "LoggedIn", sender: nil)
            }
        }
        
        //MARK: LoginButton style configuration
        loginButton.layer.cornerRadius = 5
        //loginButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        loginButton.layer.shadowOpacity = 0.25
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        
        //MARK: Email field style configuration
        emailField.layer.cornerRadius = 5
        
        
    }
    
    
    //MARK: Usuário já existente
    @IBAction func loginTapped(_ sender: Any) {
        if let email = self.emailField.text, let password = self.passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                if error == nil {
                    print("Login realizado com sucesso")
                    
                    self.performSegue(withIdentifier: "LoggedIn", sender: nil)
                }else{
                    print("Login falhou")
                    
                    let alert = UIAlertController(title: "Ops, algo está errado!", message: "Verifique se email e senha foram digitados corretamente", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)

                }
            })
            
        }
    
    }
    
    @IBAction func didTapCreate(_ sender: Any) {
        
        if let email = self.emailField.text, let password = self.passwordField.text {
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                if error == nil {
                    FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
                    print("Novo usuário criado com sucesso!")
                }else{
                    print("Autenticação de novo usuário falhou!")
                }
            })
        }
        
    }
    
}

