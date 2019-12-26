/*
Copyright 2019 Robert Wünsche

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// my own small Dyna inspired implementation
// tailored toward ML'ish puropses

// features
// * supports equal assignments of functions:
//      ex: add1(X) = X+1.
// * supports dense and sparse arrays
//
// * interpreter only supports  sqrt(X), exp(X), abs(X), pow(X, Y), sin(X), cos(X), min(X, Y), max(X, Y)  functions

// limitations
// * only supports forward inference.
//   Implies that no backward queries are implemented at all.
// * only supports
//   += aggregation
//   := assignment
//   min= aggregation
//   max= aggregation
// * only supports variable constraints:
//      ex:
//         a(0) += b(I,J)
//   doesn't support integer constraints
//      ex:
//         a(0) += b(0,J)
//   support variable constraints
//      ex:
//         a(0) += b(I,I)
// * function with equal (=) only support variables
//   doesn't support
//   a(0) = 5
//   a(1) = 7
// 
// 
// * interpreter can't use variables (program has to get processed with forward inference before interpretation)


// TODO< unittest assignConstraint() >

// TODO< unittest ConstraintUtils.intersection() >








// TODO< track open instructions in tracer correctly >



// TODO< implement integer constraint ex: a(I,0) >

package dyna;

class Dyna {
    // TODO< move to Assert class >
    public static function AssertEqFloat(a:Float, b:Float) {
        if(Math.abs(a-b)>0.0001) {
            throw 'assert($a == $b) failed!';
        }
    }

    // check BackwardRecursiveStrategy
    public static function UnittestBackwardRecStrategy1() {
        var varFile = new VarFile();
        varFile.vars.set("a", ArrObj.create([5.0, 2.0]));

        var strategy = new BackwardRecursiveStrategy(varFile);
        strategy.verbose = true;
        strategy.prgm = [
            // b(X) := a(X)+8.0.
            Term.Assign(Aggregation.NONE,Op.Arr("b",[Op.Var("X")]),  [Op.AddArr([Op.Arr("a",[Op.Var("X")]), Op.ConstFloat(8.0)])]),
        ];


        // b(0)
        var queryExpr:Op = Op.Arr("b", [Op.ConstInt(0)]);
        var result: Float = strategy.lookup(queryExpr);
        AssertEqFloat(13.0, result);
        Sys.println(result); // compute solution
    }

    public static function main() {
        UnittestUnroller.testOneVars2();
        UnittestUnroller.testTwoVars();

        UnittestBackwardRecStrategy1();

        { // check BackwardRecursiveStrategy
            
            var varFile = new VarFile();
            varFile.vars.set("a", ArrObj.create([5.0, 2.0]));

            var strategy = new BackwardRecursiveStrategy(varFile);
            strategy.verbose = true;
            strategy.prgm = [
                // b(X) := a(X)+8.0.
                Term.Assign(Aggregation.NONE,Op.Arr("b",[Op.Var("X")]),  [Op.AddArr([Op.Arr("a",[Op.Var("X")]), Op.ConstFloat(8.0)])]),
            ];


            // b(0)
            var queryExpr:Op = Op.Arr("b", [Op.ConstInt(0)]);
            Sys.println(strategy.lookup(queryExpr)); // compute solution

            // repeat to see if it memorized
            Sys.println(strategy.lookup(queryExpr)); // compute solution

        }
        //return; // we don't care about the other tests for now
        
        var varFile:VarFile = new VarFile();
        varFile.vars.set("a", ArrObj.create([5.0, 2.0]));
        varFile.vars.set("b", ArrObj.create([0.11, 0.9]));
        varFile.vars.set("d", ArrObj.create2([[0.11, 0.9], [0.11, 0.9]]));

        varFile.vars.set("x", ArrObj.create([0.3]));
        varFile.vars.set("y", ArrObj.create([0.3, 0.1, 0.2]));



        // sigmoid activation
        // l(0) := 1.0/(1.0 + exp(-x(0))).
        var as1 = Term.Assign(Aggregation.NONE,Op.Arr("l",[Op.ConstInt(0)]),   [Op.Div(Op.ConstFloat(1.0), Op.AddArr([Op.ConstFloat(1.0), Op.Arr("exp", [Op.UnaryNeg(Op.Arr("x", [Op.ConstInt(0)]))])]) )]);
        Executive.execAssign(as1, varFile);

        // c(0) := a(0)*b(0) + l(0).
        var as0 = Term.Assign(Aggregation.NONE,Op.Arr("c",[Op.ConstInt(0)]),   [Op.AddArr([Op.MulArr([Op.Arr("a", [Op.ConstInt(0)]), Op.Arr("b", [Op.ConstInt(0)])]), Op.Arr("l", [Op.ConstInt(0)])])]);
        Executive.execAssign(as0, varFile);

        trace(varFile.vars.get("l").map.get("0"));
        trace(varFile.vars.get("c").map.get("0"));

        var assigns:Array<Term> = [];

        { // test "unroll" mechanism
            var as2 = Term.Assign(Aggregation.ADD,
                Op.Arr("c",[Op.ConstInt(0)]),
                [Op.Arr("a",[Op.Var("I")])]
            );

            assigns = assigns.concat(new Unroller().unroll(as2, varFile));

            Sys.println(PrgmUtils.convToStr(assigns));
        }


        
        { // gen code for c(0) += a(I)*b(I).
            trace('-----');

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = [
                Term.Assign(Aggregation.ADD,
                    Op.Arr("c",[Op.ConstInt(0)]),
                    [Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("b",[Op.Var("I")])])]
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));
        }

        { // gen code for c(0) += a(I)*d(I,J).
            trace('-----');

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = [
                Term.Assign(Aggregation.ADD,
                    Op.Arr("c",[Op.ConstInt(0)]),
                    [Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("d",[Op.Var("I"), Op.Var("J")])])]
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));
        }

        { // gen code for c(0) += a(I)*d(I,I).
            trace('-----');

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = [
                Term.Assign(Aggregation.ADD,
                    Op.Arr("c",[Op.ConstInt(0)]),
                    [Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("d",[Op.Var("I"), Op.Var("I")])])]
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));
        }


        { // gen code for c(J) += a(I)*d(I,J).
            trace('-----');

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = [
                Term.Assign(Aggregation.ADD,
                    Op.Arr("c",[Op.Var("J")]),
                    [Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("d",[Op.Var("I"), Op.Var("J")])])]
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));
        }



        { // gen code for sqrtP2(X) = sqrt(X*2).   c(I) += sqrtP2(a(I)).
            trace('-----');

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = [
                Term.Equal(Op.Arr("sqrtP2",[Op.Var("X")]), [Op.Arr("sqrt", [Op.MulArr([Op.Var("X"), Op.ConstFloat(2.0)])])]),

                Term.Assign(Aggregation.ADD,
                    Op.Arr("c",[Op.Var("I")]),
                    [Op.MulArr([Op.Arr("sqrtP2",[Op.Arr("a",[Op.Var("I")])])])]
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));
        }


        { // program with complex activation function
            trace('-----');

            var ePow2x = Op.Arr("exp", [Op.MulArr([Op.ConstFloat(2.0), Op.Arr("y", [Op.Var("I")])])]);

            var prgm = [
                Term.Assign(Aggregation.NONE,Op.Arr("l",[Op.Var("I")]),   [Op.Div(Op.AddArr([ePow2x, Op.ConstFloat(-1.0)]), Op.AddArr([ePow2x, Op.ConstFloat(1.0)]))]), // l(i) := (e^(2x) - 1)/(e^(2x) + 1)
            ];

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = prgm;
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));
        }
    }
}

class UnittestUnroller {
    // tests if a(I,I) is correcty parsed
    public static function testOneVars2() {
        var op:Op = Op.Arr("a", [Op.Var("I"), Op.Var("I")]);
        var res = new Map<String, Array<String>>();
        Unroller.retArrAccess(op, res);
        
        var keys = [for (k in res.keys()) k];
        
        if (keys.length != 1 || keys[0] != "I") {
            trace('keys = $keys');
            throw "keys must be [I]";
        }

        if (res.get("I").length != 1 || res.get("I")[0] != "a") {
            throw "unittest failed";
        }
    }
    
    // tests if a(I,J) is correcty parsed
    public static function testTwoVars() {
        var op:Op = Op.Arr("a", [Op.Var("I"), Op.Var("J")]);
        var res = new Map<String, Array<String>>();
        Unroller.retArrAccess(op, res);
        
        var keys = [for (k in res.keys()) k];
        
        if (keys.length != 2 || keys[0] != "J" || keys[1] != "I") {
            trace('keys = $keys');
            throw "keys must be [J, I]";
        }

        if (res.get("I").length != 1 || res.get("I")[0] != "a") {
            throw "unittest failed";
        }

        if (res.get("J").length != 1 || res.get("J")[0] != "a") {
            throw "unittest failed";
        }
    }
}

// unrolls a(0) += b(J)  to a(0) += b(0), a(0) += b(1), etc.
class Unroller {
    public var uniqueVarCounter = 0; // used to enumerate unique variable names

    public var fnDefs: Array<Term> = []; // user defined function defs in Dyna program
                                         // functions are assigned with "="(equal) symbol
                                         // contains whole function definitions

    public function new() {}

    // looks up a user-defined function by name and number of args
    // returns null if no function was found
    public function lookupUserDefFn(name:String, nArgs:Int): Term {
        for (iFnDef in fnDefs) {
            switch(iFnDef) {
                case Equal(Arr(iFnName, iArgs), _):
                if (iFnName == name && iArgs.length == nArgs) {
                    return iFnDef; // found
                }
                case _:
                trace("soft internal error - expected equal as fn-def");
            }
        }
        return null; // nothing found
    }

    // expects a Assign(=) term and replaces all vars by unique substituions by the vars in the head
    // public for testing
    public function substFnWithUniqueVarnames(term:Term): Term {
        switch(term) {
            case Equal(head, [body]):
            switch(head) {
                case Arr(headArrName, headArgs):

                // we need to replace all vars in head with unique new vars
                var substHead:Op = head; // substituded head
                var substBody:Op = body; // substituded body

                for(iHeadArg in headArgs) { // loop to substitude each var with a unique var in head and body
                    switch(iHeadArg) {
                        case Var(iVarName):
                        var uniqueVarName:String = '|${uniqueVarCounter++}'; // need to gen unique var-name
                        substHead = OpUtils.subst(substHead, Var(iVarName), Var(uniqueVarName)); // substitude
                        substBody = OpUtils.subst(substBody, Var(iVarName), Var(uniqueVarName)); // substitude
                        case _:
                    }
                }

                return Equal(substHead,[substBody]);

                case _:
                throw "Expected Arr as head   ex: a(I)";
            }

            case _:
            throw "Internal Error - expected Equal with one conjunction"; // is a internal error because something gone horibly wrong
        }
    }

    // TODO< move into utils of Op >
    // substitue by calling function
    // calls a function for all recursivly ops, recursion terminates (for the branch) when function returns false as the recur value
    public static function substByFn(term:Op, fn:(Op)->{res:Op, recur:Bool}): Op {
        var callee:{res:Op, recur:Bool} = fn(term);
        var res = callee.res;
        if (callee.recur) {
            res = switch (callee.res) {
                case Var(name): callee.res;
                case ConstFloat(val): callee.res;
                case ConstInt(val): callee.res;
                
                case Arr(arrName, args):
                Arr(arrName, [for(iArg in args) substByFn(iArg, fn)]);
                
                case AddArr(args):
                AddArr([for(iArg in args) substByFn(iArg, fn)]);

                case MulArr(args):
                MulArr([for(iArg in args) substByFn(iArg, fn)]);

                case Div(arg0, arg1):
                Div(substByFn(arg0, fn), substByFn(arg1, fn));

                case UnaryNeg(arg):
                UnaryNeg(substByFn(arg, fn));

                case Trinary(cond, truePath, falsePath):
                Trinary(
                    substByFn(cond, fn),
                    substByFn(truePath, fn),
                    substByFn(falsePath, fn)
                );
                
                case TempVal(name): callee.res;
            }
        }
        return res;
    }

    // substitudes all arr-accesses by the known function body for all known functions
    public function substFnDefsByBody(op:Op): Op {
        // function to substitute and decide if the subst process continues recursivly
        function recurSubstFn(op:Op): {res:Op, recur:Bool} {
            switch(op) {
                case Arr(headArrName, headArgs):

                // * now we need to lookup if we know any function with the headArrName
                var fn:Term = lookupUserDefFn(headArrName, headArgs.length);
                if (fn == null) { // was no function found with the name and arguments?
                    return {res:op, recur:true}; // continue recursivly
                }

                // * now we need to replace all vars in fn with unique vars
                fn = substFnWithUniqueVarnames(fn);

                // we have to replace the arr by the body of the function with correctly substituded parameters in the head
                {
                    var rewriteFnBody: Op = null; // function body which we are rewriting

                    switch(fn) {
                        case Equal(Arr(_, fnHeadArgs), [fnBody]):

                        rewriteFnBody = fnBody; // current rewrite of the fn body is the current fn body

                        for(iArgIdx in 0...headArgs.length) { // iterate over all args of the fn invocation
                            // lookup argument in head headArgs and rewrite fn body with var as looked up by fnHeadArgs
                            var iCalleeHeadArg:Op = fnHeadArgs[iArgIdx];
                            var iCallerHeadArg:Op = headArgs[iArgIdx];

                            //trace('rewrite');
                            //trace('   ${OpUtils.convToStr(rewriteFnBody)}');
                            //trace('   ${OpUtils.convToStr(iCalleeHeadArg)}');
                            //trace('   ${OpUtils.convToStr(iCallerHeadArg)}');
                            rewriteFnBody = OpUtils.subst(rewriteFnBody, iCalleeHeadArg, iCallerHeadArg);
                            //trace('|-');
                            //trace('   ${OpUtils.convToStr(rewriteFnBody)}');
                        }

                        case _:
                        throw "Internal Error - expected Equal with one conjunction"; // is a internal error because something gone horibly wrong
                    }

                    return {res:rewriteFnBody, recur:false}; // we don't want to process it recursivly
                }

                case _:
                return {res:op, recur:true}; // continue with recursion
            }
        }
        
        return substByFn(op, recurSubstFn); // do recursive replacement process
    }

    public function unroll(term:Term, varFile:VarFile):Array<Term> {
        var resArr:Array<Term> = [];

        switch(term) {
            case Term.Assign(aggr, Op.Arr(arrNameDest, destIdxs), [body]):
            
            var body2:Op = substFnDefsByBody(body); // body2 is the body after "inlineing" of function definitions

            // compute accessed (array) variables by variable name
            // ex: a(I)*b(I) -> I has array-vars [a, b]
            var arrayVarsByVariable = new Map<String, Array<String>>();
            retArrAccess(body2, arrayVarsByVariable);

            if(false) { // debug content of arrayVarsByVariable
                for(iKey in arrayVarsByVariable.keys()) {
                    var varNames = arrayVarsByVariable[iKey];
                    trace('$iKey : $varNames');
                }
            }
            
            var ruleAccesses:Array<{rule:String, params:Array<Op>}> = OpUtils.retRuleAccesses(body2);

            var commonVarAssignments: Array<VarAssigment> = []; // constraints which are common between all used rules
            { // compute common constraints
                { // init with first constraint
                    var rule0 = ruleAccesses[0].rule; // name of the first accessed rule
                    var params0 = ruleAccesses[0].params; // parameters

                    if( !varFile.vars.exists(rule0) ) { // check if the accessed rule doesn't map to a variable
                        throw 'Compilation Error: $rule0 is not a known variable!';
                    }
                    var arr:ArrObj = varFile.vars.get(rule0); // fetch array by name

                    //trace('rule=$rule0 params=${params0.map(i -> OpUtils.convToStr(i))}');
                    commonVarAssignments = FnConstraintSolver.assignConstraint(params0, arr);
                }

                // iterate over all other rules and narrow constraints down
                for (iAccessIdx in 1...ruleAccesses.length) {
                    var iRuleAccess = ruleAccesses[iAccessIdx];

                    var ruleN = iRuleAccess.rule; // name of the first accessed rule
                    var paramsN = iRuleAccess.params; // parameters

                    if( !varFile.vars.exists(ruleN) ) { // check if the accessed rule doesn't map to a variable
                        throw 'Compilation Error: $ruleN is not a known variable!';
                    }
                    var arr:ArrObj = varFile.vars.get(ruleN); // fetch array by name

                    //trace('rule=$ruleN params=${paramsN.map(i -> OpUtils.convToStr(i))}');
                    var thisVarAssigments = FnConstraintSolver.assignConstraint(paramsN, arr);
                    commonVarAssignments = ConstraintUtils.calcCommonConstraints(commonVarAssignments, thisVarAssigments); // constraints have to have common elements if they intersect or they have to be the cartesian product if not
                }
            }




            function instantiateBodyWithVarAssigment(varAssignment:VarAssigment):Term {
                var righthandSide:Op = body2;
                
                // replace vars of righthandside
                for (iAssigmentVarName in varAssignment.assignments.keys()) {
                    var assignedIndex:Int = varAssignment.assignments.get(iAssigmentVarName); // the assigned index for the variable
                    var replaceOp:Op = Op.ConstInt(assignedIndex);// Op with which we substitute it
                    righthandSide = OpUtils.replaceVar(righthandSide, iAssigmentVarName, replaceOp);
                }

                // replace vars of lefthandside
                var lefthandSide:Op = Op.Arr(arrNameDest, destIdxs);
                for (iAssigmentVarName in varAssignment.assignments.keys()) {
                    var assignedIndex:Int = varAssignment.assignments.get(iAssigmentVarName); // the assigned index for the variable
                    var replaceOp:Op = Op.ConstInt(assignedIndex);// Op with which we substitute it
                    lefthandSide = OpUtils.replaceVar(lefthandSide, iAssigmentVarName, replaceOp);
                }
                
                return Term.Assign(aggr, lefthandSide, [righthandSide]);
            }
            
            // instantiate body of Rule for each variable assignment
            for (iVarAssignment in commonVarAssignments) {
                resArr.push(instantiateBodyWithVarAssigment(iVarAssignment));
            }

            case Assign(_,_,_):
            resArr.push(term); // just emit it as output

            case Impl(_,_):
            resArr.push(term); // just emit it as output

            case Equal(head, body):
            fnDefs.push(term); // is function definition - just remember it
        }

        return resArr;
    }

    // public for unittesting
    // helper
    // returns all accessed variable array names by variable name
    public static function retArrAccess(op:Op, res:Map<String, Array<String>>) {
        function hasOnlyVars(ops:Array<Op>):Bool {
            return ops.filter(v -> {
                return switch(v) {
                    case Var(_): true;
                    case _: false;
                }
                }).length == ops.length;
        }

        // expects that ops are only variables
        function retVarNames(ops:Array<Op>):Array<String> {
            return SetUtil.uniqueSet(ops.map(iOp -> return switch(iOp) {
                case Var(name): name;
                case _: throw "Expected only Var!";
            }));
        }

        switch(op) {
            case Var(name):
            case ConstFloat(val):
            case ConstInt(val):
            
            // is function?
            case Arr(fnName, args) if (["exp","sqrt","abs","pow","cos","sin","min","max","log"].filter(iv -> iv == fnName).length > 0):
            for(iArg in args) retArrAccess(iArg, res);
            
            case Arr(arrName, idxs) if (hasOnlyVars(idxs)): // is array access   ex: a(I)            
            for (iVarName in retVarNames(idxs)) { // iterate over all variable names of array access
                {
                    var found=false;
                    for(iKey in res.keys()) {
                        if (iKey == iVarName) {
                            found=true;
                            break;
                        }
                    }

                    if (!found) {
                        res.set(iVarName, []);
                    }
                }
                var varnames = res.get(iVarName);

                var found=false;
                for(iName in varnames) {
                    if (iName == arrName) {
                        found=true;
                        break;
                    }
                }

                if(!found) { // necessary because it is supposed to be a set
                    varnames.push(arrName);
                }
                res.set(iVarName, varnames);
            }

            


            case Arr(name, idxs):
            // ignore
            trace('warning - ignore Arr');

            case AddArr(args):
            for(iArg in args) retArrAccess(iArg, res);

            case MulArr(args):
            for(iArg in args) retArrAccess(iArg, res);

            case Div(arg0, arg1):
            retArrAccess(arg0, res);
            retArrAccess(arg1, res);

            case UnaryNeg(arg):
            retArrAccess(arg, res);

            case Trinary(cond, truePath, falsePath):
            retArrAccess(cond, res);
            retArrAccess(truePath, res);
            retArrAccess(falsePath, res);
            
            case TempVal(name):
            return;
        }
    }
}

// variable file, holds all variables
class VarFile {
    public var vars:Map<String, ArrObj> = new Map<String, ArrObj>();
    public function new() {}
}

// utilities for interpretation
class InterpreterUtils {
    // can the term have arguments?
    /* commented because not used
    public static function canHaveArgs(term:Op):Bool {
        return switch (term) {
            case Var(_): false;
            case ConstFloat(_): false;
            case ConstInt(_): false;
            case Arr(_,_): true;
            case AddArr(_): true;
            case MulArr(_): true;
            case Div(arg0, arg1): false;
            case UnaryNeg(arg): false;
            case Trinary(cond, truePath, falsePath): false;
            case TempVal(name): false;
        }
    } */

    // return arguments (if there are any)
    public static function retArgs(term:Op): Array<Op> {
        return switch (term) {
            case Var(_): [];
            case ConstFloat(_): [];
            case ConstInt(_): [];
            case Arr(_,args): args;
            case AddArr(args): args;
            case MulArr(args): args;
            case Div(arg0, arg1): [arg0, arg1];
            case UnaryNeg(arg): [arg];
            case Trinary(cond, truePath, falsePath): [cond,truePath,falsePath];
            case TempVal(name): [];
        }
    }

    // compute result with actual values of arguments
    public static function calcWithValOfArgs(term:Op, valOfArgs:Array<Float>): Float {
        return switch (term) {
            case Var(_): throw "Can't compute value of variable!";
            case ConstFloat(val): val;
            case ConstInt(val): val;

            case Arr("exp",[_]) if (valOfArgs.length == 1):
            return Math.exp(valOfArgs[0]);
            case Arr("sqrt",[_]) if (valOfArgs.length == 1):
            return Math.sqrt(valOfArgs[0]);
            case Arr("abs",[_]) if (valOfArgs.length == 1):
            return Math.abs(valOfArgs[0]);
            case Arr("pow",[_,_]) if (valOfArgs.length == 2):
            return Math.pow(valOfArgs[0],valOfArgs[1]);
            case Arr("cos",[_]) if (valOfArgs.length == 1):
            return Math.cos(valOfArgs[0]);
            case Arr("sin",[_]) if (valOfArgs.length == 1):
            return Math.sin(valOfArgs[0]);
            case Arr("min",[_,_]) if (valOfArgs.length == 2):
            return Math.min(valOfArgs[0],valOfArgs[1]);
            case Arr("max",[_,_]) if (valOfArgs.length == 2):
            return Math.max(valOfArgs[0],valOfArgs[1]);
            case Arr("log",[_]) if (valOfArgs.length == 1):
            return Math.log(valOfArgs[0]); // TODO< do we choose base e log? >

            case Arr(_,_): throw "Can't compute not specified Arr!"; // because we don't do variable lookups here or because the arguments don't match up

            case AddArr(args):
            if (args.length != valOfArgs.length) throw "Args length must match up!";
            var res=0.0;
            for(iRes in valOfArgs) {
                res+=iRes;
            }
            res;

            case MulArr(args):
            if (args.length != valOfArgs.length) throw "Args length must match up!";
            var res=1.0;
            for(iRes in valOfArgs) {
                res*=iRes;
            }
            res;

            case Div(_, _):
            if (valOfArgs.length != 2) throw "Expected two arguments!";
            valOfArgs[0]/valOfArgs[1];

            case UnaryNeg(_):
            if (valOfArgs.length != 1) throw "Expected one argument!";
            -valOfArgs[0];

            case Trinary(_, _, _):
            if (valOfArgs.length != 3) throw "Expected three arguments!";
            return valOfArgs[0] >= 0.5 ? valOfArgs[1] : valOfArgs[2];

            case TempVal(name): throw "Can't compute value of variable!";
        }
    }
}

class Executive {
    public function new() {}

    // executes assignment recursivly
    public static function execAssign(assign:Term, varFile:VarFile) {
        switch (assign) {
            case Assign(Aggregation.NONE, dest, [body]): // handle body with one conjunction

            var val = calc(body, varFile);

            switch(dest) {
                case Arr(name, idxs):
                {
                    var indices:Array<Int> = idxs.map(iIdx -> Std.int(calc(iIdx, varFile))); // compute concrete indices

                    trace('access dest $name(${indices.map(v -> '$v').join(", ")})');
                    var idxStrKey:String = indices.map(v -> '$v').join("_"); // convert index to string key

    	            var arr:ArrObj = varFile.vars.get(name);
                    if (arr == null) {
                        arr = new ArrObj(idxs.length);
                        varFile.vars.set(name, arr);
                    }

                    if (arr.isDense()) {
                        if (arr.dim == 1) {
                            arr.dense[indices[0]] = val;
                        }
                        else if (arr.dim == 2) {
                            arr.denseSetAt2(indices[0], indices[1], val);
                        }
                        else {
                            throw "Interpreter doesn't support more than two dimensions!";
                        }
                    }
                    else {
                        arr.map.set(idxStrKey, val);
                    }
                }

                case _:
                throw "Expected Arr!";
            }

            case _:
            throw "Not implemented!";
        }
    }

    public static function calc(op:Op, varFile:VarFile): Float {
        switch(op) {
            case Var(name):
            throw "Not implemented!";
            case ConstFloat(val):
            return val;
            case ConstInt(val):
            return val;

            case Arr("exp",[arg]):
            return Math.exp(calc(arg, varFile));
            case Arr("sqrt",[arg]):
            return Math.sqrt(calc(arg, varFile));
            case Arr("abs",[arg]):
            return Math.abs(calc(arg, varFile));
            case Arr("pow",[arg0,arg1]):
            return Math.pow(calc(arg0, varFile),calc(arg1, varFile));
            case Arr("cos",[arg]):
            return Math.cos(calc(arg, varFile));
            case Arr("sin",[arg]):
            return Math.sin(calc(arg, varFile));
            case Arr("min",[arg0,arg1]):
            return Math.min(calc(arg0, varFile),calc(arg1, varFile));
            case Arr("max",[arg0,arg1]):
            return Math.max(calc(arg0, varFile),calc(arg1, varFile));
            case Arr("log",[arg]):
            return Math.log(calc(arg, varFile));
            case Arr(name, args):
            { // it is a array access
                var indices:Array<Int> = args.map(iIdx -> Std.int(calc(iIdx, varFile))); // compute concrete indices
                var arr:ArrObj = varFile.vars.get('$name');
                trace('read $name(${indices.map(v -> '$v').join(", ")})');
                return ArrObjUtils.readAt(arr, indices);
            }

            case AddArr(args):
            {
                var resArr:Array<Float> = args.map(iArg -> calc(iArg, varFile));
                var res=0.0;
                for(iRes in resArr) {
                    res+=iRes;
                }
                return res;
            }

            case MulArr(args):
            {
                var resArr:Array<Float> = args.map(iArg -> calc(iArg, varFile));
                var res=1.0;
                for(iRes in resArr) {
                    res*=iRes;
                }
                return res;
            }

            case Div(arg0, arg1):
            return calc(arg0, varFile)/calc(arg1, varFile);

            case UnaryNeg(arg):
            return -calc(arg, varFile);

            case Trinary(cond, truePath, falsePath):
            return (calc(cond, varFile) >= 0.5 ? calc(truePath, varFile) : calc(falsePath, varFile));

            case TempVal(name):
            throw "Not implemented!!";

            case _:
            throw "Invalid!";
        }
    }
}

enum Aggregation {
    NONE; // :=
    ADD; // +=
    MIN; // min=
    MAX; // max=
}

enum Term {
    // body is always a conjuction of Op's (which is called term in the literatur of Dyna)
    Equal(head:Op, body:Array<Op>); // equal, to define something, ex: add1(X) = X+1.
    Assign(aggr:Aggregation, head:Op, body:Array<Op>); // assignment: ex: b(0) := a(0).   or   b(0) += 5.
    Impl(head:Op, body:Array<Op>); // implication from datalog, ex:  a :- c.
}

// TODO< rename to Expr >
enum Op {
    Var(name:String); // variable access, ex: a(I), where I is the variable
    ConstFloat(val:Float);
    ConstInt(val:Int);
    Arr(name:String, args:Array<Op>); // can be many things
                                      // array access, indices are for each dimension
                                      // generalized function call
    AddArr(args: Array<Op>);
    MulArr(args: Array<Op>);
    Div(arg0:Op, arg1:Op);

    UnaryNeg(arg: Op); // unary negation

    Trinary(cond: Op, truePath:Op, falsePath:Op); // trinary condition, cond is checked for >= 0.5

    // used for internal code generation
    TempVal(name:String); // access to temporary value
}

class OpUtils {
    public static function eq(a:Op, b:Op): Bool {
        return switch(a) {
            case Var(name):
            switch(b) {
                case Var(nameb) if(name==nameb): true;
                case _:false;
            }
            case ConstFloat(val):
            switch(b) {
                case ConstFloat(valb) if(val==valb): true; // TODO< compare with epsilon >
                case _:false;
            }
            case ConstInt(val):
            switch(b) {
                case ConstInt(valb) if(val==valb): true;
                case _:false;
            }
            case Arr(name, args):
            switch(b) {
                case Arr(nameb, argsb) if(name==nameb&&args.length==argsb.length):
                for(idx in 0...args.length) {
                    if (!eq(args[idx],argsb[idx]))  return false;
                }
                true;
                case _:false;
            }
            case AddArr(args):
            switch(b) {
                case AddArr(argsb) if(args.length==argsb.length):
                for(idx in 0...args.length) {
                    if (!eq(args[idx],argsb[idx]))  return false;
                }
                true;
                case _:false;
            }
            case MulArr(args):
            switch(b) {
                case MulArr(argsb) if(args.length==argsb.length):
                for(idx in 0...args.length) {
                    if (!eq(args[idx],argsb[idx]))  return false;
                }
                true;
                case _:false;
            }
            case Div(arg0, arg1):
            switch(b) {
                case Div(arg0b,arg1b) if (eq(arg0,arg0b)&&eq(arg1,arg1b)): true;
                case _:false;
            }

            case UnaryNeg(arg):
            switch(b) {
                case UnaryNeg(argb) if (eq(arg,argb)):true;
                case _:false;
            }

            case Trinary(cond, truePath, falsePath):
            switch(b) {
                case Trinary(condB, truePathB, falsePathB) if(eq(cond, condB) && eq(truePath, truePathB) && eq(falsePath, falsePathB)): true;
                case _: false;
            }

            case TempVal(name):
            switch(b) {
                case TempVal(nameb) if(name==nameb): true;
                case _: false;
            }
        }
    }

    public static function convToStr(op:Op): String {
        switch(op) {
            case Var(name):
            return name;
            case ConstFloat(val):
            return '$val';
            case ConstInt(val):
            return '$val';


            case Arr(name, idxs):
            return '$name(${idxs.map(iIdx -> convToStr(iIdx)).join(", ")})';
            
            case AddArr(args):
            {
                var resArr:Array<String> = args.map(iArg -> convToStr(iArg));
                return "(" + resArr.join(" + ") + ")";
            }

            case MulArr(args):
            {
                var resArr:Array<String> = args.map(iArg -> convToStr(iArg));
                return "(" + resArr.join(" * ") + ")";
            }

            case Div(arg0, arg1):
            return "("+convToStr(arg0)+"/"+convToStr(arg1)+")";

            case UnaryNeg(arg):
            return "-"+convToStr(arg);

            case Trinary(cond, truePath, falsePath):
            return '((${convToStr(cond)}) >= 0.5 ? (${convToStr(truePath)}) : (${convToStr(falsePath)}))';

            case TempVal(name):
            return 'TEMP_$name';
        }
    }

    
    // substitutes a Op search with replacement
    public static function subst(op:Op, search:Op, replacement:Op): Op {
        if (OpUtils.eq(op, search)) {
            return replacement;
        }

        switch(op) {
            case Arr(name, args):
            {
                var substIdxs = args.map(iArg -> subst(iArg, search, replacement));
                return Arr(name, substIdxs);
            }

            case AddArr(args):
            return AddArr(args.map(iArg -> subst(iArg, search, replacement)));

            case MulArr(args):
            return MulArr(args.map(iArg -> subst(iArg, search, replacement)));

            case Div(arg0, arg1):
            return Div(subst(arg0, search, replacement), subst(arg1, search, replacement));

            case UnaryNeg(arg):
            return UnaryNeg(subst(arg, search, replacement));

            case Trinary(cond, truePath, falsePath):
            return Trinary(subst(cond, search, replacement), subst(truePath, search, replacement), subst(falsePath, search, replacement));

            case _:
            return op; // return without any change for all others
        }
    }

    // helper
    // replaces a variable with a actual value(index)
    public static function replaceVar(op:Op, varname:String, replacement:Op): Op {
        return subst(op, Var(varname), replacement);
    }

    // TODO REFACTOR< pull out and unittest >
    // Compute which rules access which constraints.
    // Does not "fold" rule accesses in any way
    // 
    // ex:    a(I,J,0)*b(I)
    //     returns
    //        [{rule:"a", params:[Op.Var("I"),Op.Var("J"),Op.ConstInt(0)]}, {rule:"b", params:[Op.Var("I")]}]
    // 
    // argument orders are always kept
    public static function retRuleAccesses(op:Op): Array<{rule:String, params:Array<Op>}> {
        // is a recursive function
        var accesses = [];

        // internal helper function to collect result recursivly
        function internalRec(op:Op) {

            switch(op) {
                case Var(name):
                case ConstFloat(val):
                case ConstInt(val):


                case Arr(fnName, args) if (["exp","sqrt","abs","pow","cos","sin","min","max","log"].filter(iv -> iv == fnName).length > 0):
                for(iArg in args) internalRec(iArg);                        
                case Arr(arrName, idxs): // is array access  ex: a(I)
                accesses.push({rule:arrName, params:idxs});
                
                case AddArr(args):
                for(iArg in args) internalRec(iArg);

                case MulArr(args):
                for(iArg in args) internalRec(iArg);

                case Div(arg0, arg1):
                internalRec(arg0);
                internalRec(arg1);


                case UnaryNeg(arg):
                internalRec(arg);

                case Trinary(cond, truePath, falsePath):
                internalRec(cond);
                internalRec(truePath);
                internalRec(falsePath);
                
                case TempVal(name):
            }
        }

        internalRec(op);

        return accesses;
    }
}

// tracks open expressions because variables changed
class OpenTerm {
    // open Term's which need to get recomputed (in order)
    // value is the name/id of the Term
    public var open:Array<String> = [];

    public function new() {}
}

// is called that way because it executes all terms in order and emits linearized code
class LinearStrategy {
    public var emitted:Array<Term> = []; // emitted result code of tracing

    public var prgm:Array<Term> = []; // actual interpreted program

    // open set
    public var open:Array<Int> = []; // indices of open instructions to compute

    public var varFile:VarFile; // used variable file

    private var unroller:Unroller = new Unroller(); // used unroller

    public function new() {}

    // puts all instructions into open set
    public function reopen() {
        open = [];
        for(iIdx in 0...prgm.length) {
            open.push(iIdx);
        }
    }
    
    // /return false if terminated
    public function traceStep():Bool {
        if (open.length == 0) {
            return false; // we are done if we don't have anything in the open set
        }

        var currentOpen:Int = open[0]; // current processed instruction
        open = open.slice(1, open.length); // remove first open
        
        var term:Term = prgm[currentOpen]; // fetch term
        emitted = emitted.concat(unroller.unroll(term, varFile)); // emit execution

        return true; // continue
    }
}

// Is a recursive backward inference execution strategy.
// Recursion is the most simple implementation, but it may lead to stack overflow for medium sized programs and problems.
//
// reference: see "A Flexible Solver for Finite Arithmetic Circuits" http://cs.jhu.edu/~jason/papers/filardo+eisner.iclp12.pdf
//            page 2
class BackwardRecursiveStrategy {
    public var prgm:Array<Term> = []; // actual interpreted program
    public var varFile:VarFile; // used variable file

    // memorized values
    // key is the string serialization of the head in question
    public var memorized:Map<String, Float> = new Map<String, Float>();
    public var memorize:Bool = true; // is memorization enabled?

    public var verbose=false;

    public function new(varFile) {
        this.varFile = varFile;
    }

    public function flushMemo() {
        memorized.clear();
    }

    // /param j is the looked up "head"
    public function lookup(j:Op): Float {
        if(verbose) trace('lookup() w/ ${OpUtils.convToStr(j)}');

        var v: Float = Math.NaN; // read value
        var isVKnown = false; // do we know anything about j?

        { // try to find it in memorization database
            var jKey:String = OpUtils.convToStr(j); // use string as key
            if (memorized.exists(jKey)) {
                if(verbose) trace('   found in memo');
                v = memorized.get(jKey);
                isVKnown = true;
            }
        }

        if (!isVKnown) switch(j) {
            case Arr(name, args):
            // try to lookup name in varfile
            if (varFile.vars.exists(name)) {
                var arr:ArrObj = varFile.vars.get(name);

                var indices:Array<Int> = args.map(iIdx -> 
                    Std.int(
                        switch (iIdx){
                            case ConstInt(v): v;
                            case _: throw 'Exec error: Not implemented/defined for index "${OpUtils.convToStr(iIdx)}"';
                })); // compute concrete indices

                v = ArrObjUtils.readAt(arr, indices);
                isVKnown = true; // now we know about v!
            }

            case ConstFloat(c):
            v=c;
            isVKnown=true;
            case ConstInt(c):
            v=c;
            isVKnown=true;

            case _:
            throw 'lookup() not valid for "${OpUtils.convToStr(j)}"';
        }

        if (!isVKnown) { // we need to compute v if it is not known
            v = compute(j);
            isVKnown = true; // we know it now
        }

        // we have a choice to choose if we want to memorize v
        if (memorize) {
            memorized.set(OpUtils.convToStr(j), v);
        }

        return v;
    }

    public function compute(j:Op): Float {
        switch(j) {
            case Arr(fnName, args) if (["exp","sqrt","abs","pow","cos","sin","min","max","log"].filter(iv -> iv == fnName).length > 0): // is it a function?

            var valOfArgs:Array<Float> = args.map(iArg -> lookup(iArg)); // lookup/compute arguments

            if(verbose) trace('compute() fn $fnName($valOfArgs)');

            // * compute result
            return InterpreterUtils.calcWithValOfArgs(j, valOfArgs); // compute result with actual values of arguments

            case Arr(arrName, args):
            // * lookup arrName in program
            var termCandidates:Array<Term> = lookupTermsByNameAndMatchingArgs(arrName, args);
            if (termCandidates.length == 0) { // didn't we find a candidate?
                // we can't continue execution because we couldn't find the Term which describes the function
                throw 'Runtime error: call "${OpUtils.convToStr(j)}" doesn\'t match with any heads in program!';
            }
            var termCandidate = termCandidates[termCandidates.length-1]; // take last one because we care about the last term definition

            switch(termCandidate) {
                case Assign(Aggregation.NONE, Arr(_, fnHeadArgs), [fnBody]):


                // * unify arguments between caller and callee and rewrite body
                var rewriteFnBody:Op = fnBody; // rewritten function body

                for (iArgIdx in 0...fnHeadArgs.length) {
                    var iCalleeHeadArg:Op = fnHeadArgs[iArgIdx];
                    var iCallerHeadArg:Op = args[iArgIdx];

                    if(verbose) trace('rewrite');
                    if(verbose) trace('   ${OpUtils.convToStr(rewriteFnBody)}');
                    if(verbose) trace('   ${OpUtils.convToStr(iCalleeHeadArg)}');
                    if(verbose) trace('   ${OpUtils.convToStr(iCallerHeadArg)}');
                    rewriteFnBody = OpUtils.subst(rewriteFnBody, iCalleeHeadArg, iCallerHeadArg);
                    if(verbose) trace('|-');
                    if(verbose) trace('    ${OpUtils.convToStr(rewriteFnBody)}');
                }
                
                if(verbose) trace('fn body rewrite result = ${OpUtils.convToStr(rewriteFnBody)}');

                

                // * lookup components
                var args:Array<Op> = InterpreterUtils.retArgs(rewriteFnBody);
                var valOfArgs:Array<Float> = args.map(iArg -> lookup(iArg)); // lookup/compute arguments

                // * compute result
                return InterpreterUtils.calcWithValOfArgs(rewriteFnBody, valOfArgs); // compute result with actual values of arguments

                case _: throw 'Runtime error: Expected x(Y) := .... term with one conjunction element!';
            }

            case _:
            // either a internal error, or todo or just not defined!
            throw 'compute not defined for "${OpUtils.convToStr(j)}"';
        }

        var args:Array<Op> = InterpreterUtils.retArgs(j);
        var valOfArgs:Array<Float> = args.map(iArg -> lookup(iArg)); // lookup/compute arguments

        return InterpreterUtils.calcWithValOfArgs(j, valOfArgs); // compute result with actual values of arguments
    }

    // looks up matching terms in the program
    // /param args is used to match existing terms in the program to fitting ones
    // /return null if no matching candidate was found
    private function lookupTermsByNameAndMatchingArgs(name:String, args:Array<Op>): Array<Term> {
        // function to check if the args can unify
        function checkUnify(a:Array<Op>, b:Array<Op>):Bool {
            if (a.length != b.length)  return false; // can't match up if it has different lengths
            for(iIdx in 0...a.length) {
                var ia:Op = a[iIdx];
                var ib:Op = b[iIdx];
                switch (ia) {
                    case Var(_): // variable can unify with anything
                    case _:
                    if (!OpUtils.eq(ia, ib))  return false;
                }
            }
            return true; // can unify if nothing failed
        }
        
        var matching = [];

        for(iTerm in prgm) {
            switch(iTerm) {
                case Assign(Aggregation.NONE, Op.Arr(headName, headArgs), _) if (headName == name && checkUnify(headArgs, args)):
                matching.push(iTerm);
                
                case _: // simply ignore
            }
        }
        
        return matching;
    }
}


// used to assign a cartesian product to the indices of arrays
// TODO< implement integer constraint ex: a(I,0) >
class FnConstraintSolver {
    // TODO< rename to calcArrConstraints() >
    // compute all possible constraints on indices of array access
    // ex: a(I,J)
    //
    // result:
    //  (I:0, J:5)
    //  (I:1, J:3)    
    public static function assignConstraint(indexConstraints:Array<Op>, arr:ArrObj): Array<VarAssigment> {
        var constraints = assignConstraintInternal(indexConstraints, arr);

        // we need to remove duplicates
        var map = new Map<String, VarAssigment>();
        for (iConstraint in constraints) {
            map.set(iConstraint.calcKey(), iConstraint);
        }

        return [for(iKey in map.keys()) map.get(iKey)];
    }

    public static function assignConstraintInternal(indexConstraints:Array<Op>, arr:ArrObj): Array<VarAssigment> {        
        if (indexConstraints.length != arr.dim) {
            trace('${indexConstraints.length}   ${ arr.dim}');
            trace('internal error: expect same length');
            return [];
        }

        var varAssignments: Array<VarAssigment> = [for (iIndex in arr.retIndices()) {
            var varAssignment = new VarAssigment();

            for(iCnstrtIdx in 0...indexConstraints.length) { // loop over constraints
                var iiIndex:Int = iIndex[iCnstrtIdx]; // "real" index inside the datastructure
                
                var indexConstraint:Op = indexConstraints[iCnstrtIdx];
                switch(indexConstraint) {
                    case Var(varname):
                    // check if constraint matches up if it already exists.
                    // is necessary for constraints ex: a(I,I)
                    if (varAssignment.hasVar(varname)) {
                        if (varAssignment.assignments.get(varname) == iiIndex) { // constraint must be satisfied
                            varAssignment.assignments.set(varname, iiIndex);
                        }
                    }
                    else {
                        varAssignment.assignments.set(varname, iiIndex);
                    }

                    case _:
                    throw "not supported constraint!";
                }
            }

            varAssignment;
        }];
        return varAssignments;
    }
}

// constraint utilities
class ConstraintUtils {
    // ex: (a: 1, b: 1) (a: 1)  --> (a: 1, b: 1)
    //     (a: 1, b: 2)             (a: 1, b: 2)

    // ex: (a: 1, b: 1) (a: 1, c: 0)  --> (a: 1, b: 1, c: 0)
    //     (a: 1, b: 2)                   (a: 1, b: 2, c: 0)


    // ex: (a: 2, b: 1) (a: 1)  --> (empty, because a=1 doesn't appear in both sides)
    
    // TODO: handle non intersections as cartesian product
    // ex: (a: 1)       (b: 1)   --> (a: 1, b: 1)
    //     (a: 2)       (b: 3)       (a: 1, b: 3)
    //                               (a: 2, b: 1)
    //                               (a: 1, b: 3)
    
    public static function calcCommonConstraints(a:Array<VarAssigment>, b:Array<VarAssigment>):Array<VarAssigment> {
        // TODO< check if vars intersect, call calcIntersect, else compute cartesian product >
        return calcIntersect(a, b);
    }

    // computes intersection of constraints, only defined when variables match up
    public static function calcIntersect(a:Array<VarAssigment>, b:Array<VarAssigment>):Array<VarAssigment> {
        var intersection = [];
        for(iA in a) {
            for(iAVarname in iA.assignments.keys()) {
                var iAValue = iA.assignments.get(iAVarname);
                
                for (iB in b) {
                    var isBConstraintFullfilled = existInAssignment(
                        iAVarname,
                        iAValue,
                        iB);
                    
                    if (isBConstraintFullfilled) {
                        intersection.push(merge(iA,iB));
                    }
                }
            }
        }

        return intersection;
    }

    // merges two var assigments into one
    // ex: (a: 1, b: 1) (a: 1, c: 0)  --> (a: 1, b: 1, c: 0)
    public static function merge(a:VarAssigment, b:VarAssigment): VarAssigment {
        var result = new VarAssigment();
        for(iAKey in a.assignments.keys()) {
            var iValue = a.assignments.get(iAKey);
            result.assignments.set(iAKey, iValue);
        }
        for(iBKey in b.assignments.keys()) {
            if(!result.hasVar(iBKey)) {
                var iValue = b.assignments.get(iBKey);
                result.assignments.set(iBKey, iValue);
            }
        }

        return result;
    }

    // do the constraints have common variables?
    public static function haveCommonVars(a:VarAssigment, b:VarAssigment):Bool {
        for (iAVarname in a.assignments.keys()) {
            if (b.hasVar(iAVarname)) {
                return true;
            }
        }
        return false;
    }

    // exist the assignment in the assigments
    private static function existInAssignment(
        varname:String,
        value:Int,
        assignment:VarAssigment): Bool
    {
        if (!assignment.hasVar(varname)) {
            return false;
        }
        return assignment.assignments.get(varname) == value;
    }
}

// array object
// can be associative or dense
class ArrObj {
    // keys are strings of indices
    public var map:Map<String, Float> = new Map<String, Float>();

    public var dense:Array<Float> = null; // is sparse if this is null

    public var width:Int = 0; // width of 2d array

    public var dim:Int; // dimensions

    public function new(dim) {
        this.dim=dim;
    }

    public function isDense() {
        return dense != null;
    }

    public function denseAt2(y:Int,x:Int):Float {
        return dense[width*y + x];
    }

    public function denseSetAt2(y:Int,x:Int,v:Float) {
        dense[width*y + x] = v;
    }

    // helper to return all possible indices
    public function retIndices(): Array<Array<Int>> {
        var res:Array<Array<Int>> = [];

        if (isDense()) {
            if (dim == 1) {
                res = [for (idx in 0...dense.length) [idx]]; // build array with all one dimensional indices
            }
            else if (dim == 2) {
                // build cartesian product of all dimension indices
                for (i in 0...Std.int(dense.length/width)) {
                    for (j in 0...width) {
                        res.push([i, j]);
                    }
                }
            }
            else {
                throw 'Not implemented for more than 2 dimensions!';
            }
        }
        else {
            for(iKey in map.keys()) {
                res.push(iKey.split("_").map(v -> Std.parseInt(v))); // split by "_" because we seperate indices with it
            }
        }

        return res;
    }

    // create dense array
    public static function create(arr:Array<Float>): ArrObj {
        var res = new ArrObj(1);
        res.dense = [for (iv in arr) iv]; // copy
        return res;
    }

    // create two dimensional dense array
    public static function create2(arr:Array<Array<Float>>): ArrObj {
        var res = new ArrObj(2);
        res.width = arr[0].length;
        res.dense = [for (i in 0...arr[0].length*arr.length) 0.0];
        for(iIdx in 0...arr.length) {
            for(jIdx in 0...arr[iIdx].length) {
                res.denseSetAt2(iIdx, jIdx, arr[iIdx][jIdx]);
            }
        }
        return res;
    }
}

class ArrObjUtils {
    public static function readAt(arr:ArrObj, indices:Array<Int>):Float {
        if (arr.isDense()) {
            if (arr.dim == 1) {
                return arr.dense[indices[0]];
            }
            else if (arr.dim == 2) {
                return arr.denseAt2(indices[0], indices[1]);
            }
            else {
                throw "Interpreter doesn't support more than two dimensions!";
            }
        }
        else { // sparse access
            var idxStrKey:String = indices.map(v -> '$v').join("_"); // convert index to string key
            return arr.map.get(idxStrKey); // lookup in database
        }
    }
}


// set helper
class SetUtil {
    public static function intersect(a:Array<Int>, b:Array<Int>) {
        var res = [];
        for(ia in a) {
            if(contains(b, ia)) {
                res.push(ia);
            }
        }
        return res;
    }

    private static function contains<T>(a:Array<T>, v:T):Bool {
        for(iv in a) {
            if (iv == v) {
                return true;
            }
        }
        return false;
    }

    // returns set with unique values
    public static function uniqueSet(a:Array<String>) {
        var res = [];
        for(iv in a) {
            if (!contains(res, iv)) {
                res.push(iv);
            }
        }
        return res;
    }
}

// used to remember and manipulate constraints for code-generation
class VarAssigment {
    public var assignments:Map<String, Int> = new Map<String, Int>();
    public function new() {}
    // does it have the variablename?
    public function hasVar(varname:String) {
        return assignments.exists(varname);
    }

    // helper to compute unique key to identify this assignment
    public function calcKey():String {
        return [for (iName in assignments.keys()) '$iName#${assignments.get(iName)}'].join("#");
    }
}

// tool to convert program to string
class PrgmUtils {
    public static function convToStr(prgm:Array<Term>): String {
        return [
            for(iTerm in prgm) {
                switch(iTerm) {
                    case Assign(aggr, dest, bodyConj):
                    var aggrStr = switch(aggr) {
                        case Aggregation.NONE:":=";
                        case Aggregation.ADD:"+=";
                        case Aggregation.MIN:"min=";
                        case Aggregation.MAX:"max=";
                    }

                    '${OpUtils.convToStr(dest)} $aggrStr ${bodyConj.map(iTerm -> OpUtils.convToStr(iTerm)).join(", ")}.';

                    case Equal(head, bodyConj):
                    '${OpUtils.convToStr(head)} = ${bodyConj.map(iTerm -> OpUtils.convToStr(iTerm)).join(", ")}.';

                    case Impl(head, bodyConj):
                    '${OpUtils.convToStr(head)} :- ${bodyConj.map(iTerm -> OpUtils.convToStr(iTerm)).join(", ")}.';
                };
            }].join("\n");
    }
}
