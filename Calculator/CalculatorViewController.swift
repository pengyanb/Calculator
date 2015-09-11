//
//  CalculatorViewController.swift
//  Calculator
//
//  Created by Yanbing Peng on 4/09/15.
//  Copyright (c) 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var stack: UILabel!
    
    @IBOutlet var buttonKeys: [UIButton]!{
        didSet{
          for button in buttonKeys
          {
            button.titleLabel?.adjustsFontSizeToFitWidth = true
          }
        }
    }
    
    
    let calcBrain  = CalcBrain()
    var userIsInTheMiddleOfEnterring = false
    var dotHasBeenEntered = false
    //var piEnteredPreviously = false
    
    var displayValue:Double?{
        get{
            if let numberValue = NSNumberFormatter().numberFromString(display.text!){
                return numberValue.doubleValue
            }else{
                return nil
            }
        }
        set{
            stack.text = calcBrain.description
            if let numberValue = newValue{
                let isInteger = floor(numberValue) == numberValue
                display.text = isInteger ? "\(Int(numberValue))":"\(numberValue)"
                
            }
            else
            {
                display.text = calcBrain.errorStr
            }
        }
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        if !userIsInTheMiddleOfEnterring
        {
            display.text = sender.currentTitle!
            userIsInTheMiddleOfEnterring = true
        }
        else
        {
            if (dotHasBeenEntered && sender.currentTitle == "."){
                println("dot entered before, return")
                return
            }
            else if sender.currentTitle == "."
            {
                println("dot entered")
                dotHasBeenEntered = true
            }
            else
            {
                println("else triggered")
            }
            display.text = display.text! + sender.currentTitle!
        }
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfEnterring = false
        dotHasBeenEntered = false
        //piEnteredPreviously = false
        if let displayValueUnwrap = displayValue{
            if let result = calcBrain.pushOperand(displayValueUnwrap)
            {
                displayValue = result
            }
        }
        
    }
    
    @IBAction func clear() {
        userIsInTheMiddleOfEnterring = false
        dotHasBeenEntered = false
        //piEnteredPreviously = false
        calcBrain.clearStack()
        displayValue = 0;
    }
    
    @IBAction func setVariableValue(sender: UIButton) {
        if let value = NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        {
            userIsInTheMiddleOfEnterring = false;
            if let result = calcBrain.setVariable("M", variableValue: value)
            {
                displayValue = result
            }
        }
    }
    @IBAction func performOperation(sender: UIButton)
    {
        if userIsInTheMiddleOfEnterring
        {
            enter()
        }
        else
        {
            println("user not in the middle of entering")
            if(sender.currentTitle! == "−")
            {
                println("− pressed")
                userIsInTheMiddleOfEnterring = true
                display.text = "-"
                return
            }
        }
        displayValue = calcBrain.performOperation(sender.currentTitle!)
    }
    
}
