//
//  CalcBrain.swift
//  Calculator
//
//  Created by Yanbing Peng on 4/09/15.
//  Copyright (c) 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class CalcBrain
{
    private enum Op: Printable
    {
        case AppendOperand(Double)
        case NullaryOperation(String, ()->Double?)
        case UnaryOperation(String, (Double)->Double)
        case BinaryOperation(String, (Double, Double)->Double)

        var description:String
        {
            get{
                switch self
                {
                case .AppendOperand(let operand):
                    return "\(operand)"
                case .NullaryOperation(let symbol, _):
                    return symbol
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                }
            }
        }
    }
    
    private var opStack = [Op]();
    private var knownOps = [String:Op]();
    private var variableValues = Dictionary<String,Double>()
    private var opPrecedence = Dictionary<String, Int>()

    var errorStr = ""
    
    var description:String{
        get{
            return describ()
        }
    }
    init()
    {
        knownOps["+"] = Op.BinaryOperation("+", {(op1:Double, op2:Double)->Double in return op2 + op1})
        knownOps["−"] = Op.BinaryOperation("−", {(op1:Double, op2:Double)->Double in return op2 - op1})
        knownOps["×"] = Op.BinaryOperation("×", {(op1:Double, op2:Double)->Double in return op2 * op1})
        knownOps["÷"] = Op.BinaryOperation("÷", {(op1:Double, op2:Double)->Double in return op2 / op1})
        knownOps["√"] = Op.UnaryOperation("√", {(op1:Double)->Double in return sqrt(op1)})
        knownOps["sin"] = Op.UnaryOperation("sin", {(op1:Double)->Double in return sin(op1)})
        knownOps["cos"] = Op.UnaryOperation("cos", {(op1:Double)->Double in return cos(op1)})
        knownOps["π"] = Op.NullaryOperation("π", {()->Double? in return M_PI})
        knownOps["M"] = Op.NullaryOperation("M", {()->Double? in return self.variableValues["M"]})
        
        opPrecedence["+"] = 1;
        opPrecedence["−"] = 1;
        opPrecedence["×"] = 2;
        opPrecedence["÷"] = 2;
    }
    private func describ()->String
    {
        errorStr = ""
        
        let describResult = describ(opStack, highestPrecedence: 0)
        errorStr = describResult.errorString
        return describResult.descriptionFragment+(describResult.showEqualSign ? " =" :"")
    }
    private func describ(opStack:[Op], highestPrecedence:Int)->(descriptionFragment:String, result:Double?, showEqualSign:Bool, errorString:String, remainingOpStack:[Op])
    {
        if !opStack.isEmpty
        {
            var remainingOpStack = opStack
            let op = remainingOpStack.removeLast()
            switch op{
            case Op.AppendOperand(let digit):
                let valueToReturn = (floor(digit) == digit) ? "\(Int(digit))":"\(digit)"
                let needBracket = digit < 0
                return ( (needBracket ? "(":"")+valueToReturn+(needBracket ? ")":""), digit, false, "", remainingOpStack)
            case Op.NullaryOperation(let symbol, let operation):
                if let result = operation(){
                    return (symbol, result, false, "", remainingOpStack)
                }else{
                    return (symbol, 1, false, "", remainingOpStack)
                }
            case Op.UnaryOperation(let symbol, let operation):
                let describReturn = describ(remainingOpStack, highestPrecedence: 0)
                if let result = describReturn.result{
                    if result < 0 && symbol == "√"
                    {
                        return (symbol+"("+describReturn.descriptionFragment+")", nil, false, "Error: Square Root of Nagetive Number", describReturn.remainingOpStack)
                    }
                    else
                    {
                        return (symbol+"("+describReturn.descriptionFragment+")", operation(result), true, "", describReturn.remainingOpStack)
                    }
                    
                }
                else{
                    return (symbol+"("+describReturn.descriptionFragment+")", nil, false, "Error: Invalid Operation", describReturn.remainingOpStack)
                }
                
            case Op.BinaryOperation(let symbol, let operation):
                let currentPrecedence = opPrecedence[symbol]!
                let needBracket = (currentPrecedence < highestPrecedence)
                let describReturn1 = describ(remainingOpStack, highestPrecedence: currentPrecedence)
                if let operand1 = describReturn1.result
                {
                    let describReturn2 = describ(describReturn1.remainingOpStack, highestPrecedence: currentPrecedence)

                    if let operand2 = describReturn2.result
                    {
                        if operand1 == 0 && symbol == "÷"
                        {
                            return ( (needBracket ? "(":"")+describReturn2.descriptionFragment+symbol+describReturn1.descriptionFragment+(needBracket ? ")":""), nil, false, "Error: Divide By 0", describReturn2.remainingOpStack)
                        }
                        else
                        {
                            return ( (needBracket ? "(":"")+describReturn2.descriptionFragment+symbol+describReturn1.descriptionFragment+(needBracket ? ")":""), operation(operand1, operand2), true, "", describReturn2.remainingOpStack)
                        }
                    }
                    else
                    {
                        return ("(?"+symbol+describReturn1.descriptionFragment+")", nil, false, describReturn2.errorString, describReturn2.remainingOpStack)
                    }
                }
                else
                {
                    return ("("+symbol+"?)", nil, false, describReturn1.errorString, describReturn1.remainingOpStack)
                }
            }
        }
        return (" ", nil, false, "Error: Operand Missing", opStack);
    }
    private func evaluate(opStack:[Op])->(result:Double?, remainingOpStack:[Op])
    {
        if count(opStack) > 0{
            var remainingOpStack = opStack
            let op = remainingOpStack.removeLast()
            switch op{
            case Op.NullaryOperation(let symbol, let operation):
                return (operation(), remainingOpStack)
            case Op.AppendOperand(let digit):
                return (digit, remainingOpStack)
            case Op.UnaryOperation(let symbol, let operation):
                let evaluatedReturn = evaluate(remainingOpStack)
                if let op1 = evaluatedReturn.result{
                    if op1 < 0 && symbol == "√"
                    {
                        return (nil, evaluatedReturn.remainingOpStack)
                    }
                    else
                    {
                        let result = operation(op1)
                        return (result, evaluatedReturn.remainingOpStack)
                    }
                }
            case Op.BinaryOperation(let symbol, let operation):
                let evaluatedReturn1 = evaluate(remainingOpStack)
                if let op1 = evaluatedReturn1.result{
                    let evaluatedReturn2 = evaluate(evaluatedReturn1.remainingOpStack)
                    if let op2 = evaluatedReturn2.result
                    {
                        if op1 == 0 && symbol == "÷"
                        {
                            return (nil, evaluatedReturn2.remainingOpStack)
                        }
                        else
                        {
                            return (operation(op1, op2), evaluatedReturn2.remainingOpStack)
                        }
                    }
                }
            }
        }
        return (nil, opStack)
    }
    func evaluate()->Double?
    {
        if !opStack.isEmpty
        {
            let evalutedResult = evaluate(opStack)
            println("OpStacks \(opStack) evaluated to result \(evalutedResult.result) and remainingStack \(evalutedResult.remainingOpStack)")
    
            return evalutedResult.result
        }
        return nil
    }
    func clearStack()
    {
        opStack = [Op]();
        variableValues = [String:Double]();
    }
    func setVariable(variableName:String, variableValue:Double)->Double?
    {
        variableValues[variableName] = variableValue
        return evaluate()
    }
    func pushOperand(digit:Double)->Double?
    {
        opStack.append(Op.AppendOperand(digit))
        return evaluate()
    }
    func performOperation(operation:String)->Double?
    {
        opStack.append(knownOps[operation]!)
        return evaluate()
    }
    
}