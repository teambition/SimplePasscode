//
//  AuthenticationViewController.swift
//  SimplePasscode
//
//  Created by Zhu Shengqi on 5/8/16.
//  Copyright © 2016 Zhu Shengqi. All rights reserved.
//

import UIKit
import SnapKit
import LocalAuthentication

class AuthenticationViewController: UIViewController {
    // MARK: - Private Properties
    fileprivate lazy var promptLabel: UILabel = {
        let promptLabel = UILabel()
        
        if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
            promptLabel.font = UIFont.systemFont(ofSize: 22)
        } else {
            promptLabel.font = UIFont.systemFont(ofSize: 18)
        }
        
        promptLabel.text = NSLocalizedString("Enter Passcode", bundle: Bundle(for: type(of: self)), comment: "Enter Passcode")
        promptLabel.textAlignment = .center
        
        return promptLabel
    }()
    
    fileprivate lazy var inputCirclesView: InputCirclesView = {
        let inputCirclesView = InputCirclesView(passcodeLength: SimplePasscode.passcodeLength)
        
        return inputCirclesView
    }()
    
    fileprivate lazy var errorPromptLabel: UILabel = {
        let errorPromptLabel = UILabel()
        
        errorPromptLabel.text = " "
        errorPromptLabel.font = UIFont.systemFont(ofSize: 14)
        errorPromptLabel.textColor = UIColor.errorRedColor
        errorPromptLabel.textAlignment = .center
        
        return errorPromptLabel
    }()
    
    fileprivate lazy var numPadView: NumPadView = {
        let numPadView = NumPadView()
        
        numPadView.delegate = self
        
        return numPadView
    }()
    
    fileprivate lazy var deleteButton: UIButton = {
        let deleteButton = UIButton(type: .system)
        
        deleteButton.setTitle(NSLocalizedString("Delete", bundle: Bundle(for: type(of: self)), comment: "Delete"), for: UIControl.State())
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        deleteButton.addTarget(self, action: #selector(self.deleteButtonTapped), for: .touchUpInside)
        
        return deleteButton
    }()
    
    fileprivate var firstAppear = true
    
    // MARK: - Public Properties
    var currentPasscode: String!
    var inputtedPasscode = ""
    var completionHandler: ((_ success: Bool) -> Void)?
    
    // MARK: - VC Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if firstAppear {
            firstAppear = false
            authenticateUsingTouchID()
        }
    }
    
    // MARK: - UI Config
    fileprivate func setupUI() {
        view.backgroundColor = UIColor.white
        view.tintColor = globalTintColor
        
        let canvasView = UIView()
        view.addSubview(canvasView)
        canvasView.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        let containerView = UIView()
        canvasView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalTo(canvasView)
        }
        
        do {
            containerView.addSubview(promptLabel)
            promptLabel.textColor = promptLabel.tintColor
            promptLabel.snp.makeConstraints { make in
                make.top.equalTo(containerView)
                make.left.equalTo(containerView)
                make.right.equalTo(containerView)
            }
            
            containerView.addSubview(inputCirclesView)
            inputCirclesView.snp.makeConstraints { make in
                make.top.equalTo(promptLabel.snp.bottom).offset(20)
                make.centerX.equalTo(containerView)
            }
            
            containerView.addSubview(errorPromptLabel)
            errorPromptLabel.snp.makeConstraints { make in
                make.top.equalTo(inputCirclesView.snp.bottom).offset(10)
                make.centerX.equalToSuperview()
            }
            
            containerView.addSubview(numPadView)
            numPadView.snp.makeConstraints { make in
                make.top.equalTo(errorPromptLabel.snp.bottom).offset(10)
                make.left.equalTo(containerView)
                make.right.equalTo(containerView)
            }
            
            containerView.addSubview(deleteButton)
            deleteButton.snp.makeConstraints { make in
                make.top.equalTo(numPadView.snp.bottom)
                make.right.equalTo(containerView)
                make.bottom.equalTo(containerView)
            }
        }
    }
    
    // MARK: - Overriden UI Behavior
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }
    
    // MARK: - Action Handlers
    @objc func deleteButtonTapped() {
        if inputtedPasscode.count > 0 {
            inputtedPasscode.remove(at: inputtedPasscode.index(before: inputtedPasscode.endIndex))
            inputCirclesView.setFilled(false, atIndex: inputtedPasscode.count)
        }
    }
    
    func authenticateUsingTouchID() {
        if allowTouchID {
            let authenticationContext = LAContext()
            let authenticationReason = NSLocalizedString("Verify your identity to continue", bundle: Bundle(for: type(of: self)), comment: "Verify your identity to continue")
            authenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: authenticationReason, reply: { (success, error) in
                DispatchQueue.main.async {
                    if success {
                        self.authenticationComplete(success: true)
                    }
                }
            })
        }
    }
    
    // MARK: - Authentication Result
    fileprivate func authenticationComplete(success: Bool) {
        if success {
            FreezeManager.clearState()
            completionHandler?(true)
        } else {
            // User should be forced to sign out when authentication fails
            completionHandler?(false)
        }
    }
}

extension AuthenticationViewController: NumPadViewDelegate {
    func numPadView(_ view: NumPadView, didTapDigit digit: Int) {
        guard inputtedPasscode.count < currentPasscode.count else {
            return
        }
        
        inputtedPasscode += "\(digit)"
        inputCirclesView.setFilled(true, atIndex: inputtedPasscode.count - 1)
        
        if inputtedPasscode.count == currentPasscode.count {
            deleteButton.isEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                if self.inputtedPasscode != self.currentPasscode {
                    FreezeManager.incrementPasscodeFailure { reachThreshold in
                        if reachThreshold {
                            self.authenticationComplete(success: false)
                        } else {
                            self.inputtedPasscode = ""
                            self.inputCirclesView.unfillAllCircles()
                            self.inputCirclesView.shake(needsVibration: true, completion: nil)
                            self.errorPromptLabel.text = String.localizedStringWithFormat(NSLocalizedString("Wrong passcode. You can retry %ld more times", bundle: Bundle(for: type(of: self)), comment: "Wrong passcode. You can retry %ld more times"), FreezeManager.chancesRemained)
                        }
                    }
                } else {
                    self.authenticationComplete(success: true)
                }
                
                self.deleteButton.isEnabled = true
            }
        }
    }
}
