//
//  RegisterVerifyMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class RegisterVerifyMobileViewController: UIViewController {

    var mobile: String!
    var areaCode: String!

    
    @IBOutlet weak var verifyMobileNumberPromptLabel: UILabel!
    @IBOutlet weak var verifyMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var phoneNumberLabel: UILabel!

    @IBOutlet weak var verifyCodeTextField: BorderTextField!
    @IBOutlet weak var verifyCodeTextFieldTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var callMePromptLabel: UILabel!
    @IBOutlet weak var callMeButton: UIButton!
    @IBOutlet weak var callMeButtonTopConstraint: NSLayoutConstraint!

    lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: "next:")
        return button
        }()
    
    lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "tryCallMe:", userInfo: nil, repeats: true)
        return timer
        }()
    var haveAppropriateInput = false {
        willSet {
            nextButton.enabled = newValue

            if newValue {
                verifyRegisterMobile()
            }
        }
    }
    var callMeInSeconds = YepConfig.callMeInSeconds()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        verifyMobileNumberPromptLabel.text = NSLocalizedString("Input verification code send to", comment: "")
        phoneNumberLabel.text = "+" + areaCode + " " + mobile

        //verifyCodeTextField.placeholder = ""
        verifyCodeTextField.delegate = self
        verifyCodeTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        callMePromptLabel.text = NSLocalizedString("Didn't get it?", comment: "")
        callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)

        verifyMobileNumberPromptLabelTopConstraint.constant = Ruler.match(.iPhoneHeights(30, 50, 60, 60))
        verifyCodeTextFieldTopConstraint.constant = Ruler.match(.iPhoneHeights(30, 40, 50, 50))
        callMeButtonTopConstraint.constant = Ruler.match(.iPhoneHeights(10, 20, 40, 40))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
        callMeButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        verifyCodeTextField.becomeFirstResponder()

        callMeTimer.fire()
    }

    // MARK: Actions

    func tryCallMe(timer: NSTimer) {
        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = NSLocalizedString("Call me", comment: "") + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation {
                    self.callMeButton.setTitle(callMeInSecondsString, forState: .Normal)
                    self.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation {
                    self.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                    self.callMeButton.layoutIfNeeded()
                }

                callMeButton.enabled = true
            }
        }

        if (callMeInSeconds > 1) {
            callMeInSeconds--
        }
    }

    @IBAction func callMe(sender: UIButton) {

        callMeTimer.invalidate()

        UIView.performWithoutAnimation {
            self.callMeButton.setTitle(NSLocalizedString("Calling", comment: ""), forState: .Normal)
            self.callMeButton.layoutIfNeeded()
        }

        delay(5) {
            UIView.performWithoutAnimation {
                self.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                self.callMeButton.layoutIfNeeded()
            }
        }

        sendVerifyCodeOfMobile(mobile, withAreaCode: areaCode, useMethod: .Call, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            if let errorMessage = errorMessage {
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    YepAlert.alertSorry(message: errorMessage, inViewController: self)

                    UIView.performWithoutAnimation {
                        self?.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                        self?.callMeButton.layoutIfNeeded()
                    }
                }
            }

        }, completion: { success in
            println("resendVoiceVerifyCode \(success)")
        })
    }

    func textFieldDidChange(textField: UITextField) {
        haveAppropriateInput = (count(textField.text) == YepConfig.verifyCodeLength())
    }

    func next(sender: UIBarButtonItem) {
        verifyRegisterMobile()
    }

    private func verifyRegisterMobile() {

        view.endEditing(true)

        let verifyCode = verifyCodeTextField.text

        YepHUD.showActivityIndicator()

        verifyMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            YepHUD.hideActivityIndicator()

            if let errorMessage = errorMessage {
                dispatch_async(dispatch_get_main_queue()) {
                    self?.nextButton.enabled = false

                    YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                        verifyCodeTextField.becomeFirstResponder()
                    })
                }
            }

        }, completion: { loginUser in

            println("\(loginUser)")

            YepHUD.hideActivityIndicator()

            dispatch_async(dispatch_get_main_queue()) {

                saveTokenAndUserInfoOfLoginUser(loginUser)

                self.performSegueWithIdentifier("showRegisterPickAvatar", sender: nil)
            }
        })
    }
}

extension RegisterVerifyMobileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            verifyRegisterMobile()
        }

        return true
    }
}

