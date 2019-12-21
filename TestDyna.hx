// my own small Dyna inspired implementation
// tailored toward ML'ish puropses

// limitations
// * only supports forward inference.
//   Implies that no backward queries are implemented at all.
// * only supports
//   += aggregation
//     * only with left hand side where constants are used
//       ex: c(0) := ...
//   := assignment
//     * only with left hand side where constants are used
//       ex: c(0) := ...
// * only supports  sqrt(X), exp(X), abs(X), pow(X, Y)  functions
// * only supports variable constraints:
//      ex:
//         a(0) += b(I,J)
//   doesn't support integer constraints
//      ex:
//         a(0) += b(0,J)
//   support variable constraints
//      ex:
//         a(0) += b(I,I)


// TODO< unittest assignConstraint() >

// TODO< unittest ConstraintUtils.intersection() >



// TODO< handle variable in head, ex >
// c(I) += a(I,J) * b(J)


// TODO< handle two variable with assignment, ex >
// c(I) := a(I,J) * b(J)


// TODO< unify := and aggregation to one enum value >



// TODO< track open instructions in tracer correctly >

// TODO< handle two variables in codegen >





// TODO< support array based storage >
// TODO< decide when to choose which datastructure >


// TODO LOW < handle *= >
//    needed for factorial example
//    :- item(fact, int, 1).
//    :- item(natural, bool, false).
//    fact(N) *= I if natural(I) & I < N.
//    natural(1)    |= true.
//    natural(=I+1) |= natural(I).
//    from https://web.archive.org/web/20170315003048/http://dyna.org/wiki/index.php/Examples#Factorial

// TODO LATER< support min= aggregate >


class TestDyna {
    public static function main() {
        UnittestUnroller.testOneVars2();
        UnittestUnroller.testTwoVars();
        
        var varFile:VarFile = new VarFile();
        varFile.vars.set("a", ArrObj.create([5.0, 2.0]));
        varFile.vars.set("b", ArrObj.create([0.11, 0.9]));
        varFile.vars.set("d", ArrObj.create2([[0.11, 0.9], [0.11, 0.9]]));

        varFile.vars.set("x", ArrObj.create([0.3]));




        // sigmoid activation
        // l(0) := 1.0/(1.0 + exp(-x(0)))
        var as1 = Term.Assign(Op.Arr("l",[Op.ConstInt(0)]),   Op.Div(Op.ConstFloat(1.0), Op.AddArr([Op.ConstFloat(1.0), Op.FnCall("exp", [Op.UnaryNeg(Op.Arr("x", [Op.ConstInt(0)]))])]) ));
        Executive.execAssign(as1, varFile);

        // c(0) := a(0)*b(0) + l(0)
        var as0 = Term.Assign(Op.Arr("c",[Op.ConstInt(0)]), Op.AddArr([Op.MulArr([Op.Arr("a", [Op.ConstInt(0)]), Op.Arr("b", [Op.ConstInt(0)])]), Op.Arr("l", [Op.ConstInt(0)])]));
        Executive.execAssign(as0, varFile);

        trace(varFile.vars.get("l").map.get("0"));
        trace(varFile.vars.get("c").map.get("0"));

        var assigns:Array<Term> = [];

        { // test "unroll" mechanism
            var as2 = Term.AccumulatorAdd(
                Op.Arr("c",[Op.ConstInt(0)]),
                Op.Arr("a",[Op.Var("I")])
            );

            assigns = assigns.concat(Unroller.unroll(as2, varFile));
        }

        for(iX in assigns) {
            Sys.println(switch(iX) {
                case AccumulatorAdd(dest, source):
                '${OpUtils.convToStr(dest)} += ${OpUtils.convToStr(source)}';
                case Assign(dest, src):
                '${OpUtils.convToStr(dest)} := ${OpUtils.convToStr(src)}';
            });
        }

        { // gen code for a(I)*b(I)
            trace('-----');

            var tracerEmitter:TracerEmitter = new TracerEmitter();
            tracerEmitter.prgm = [
                Term.AccumulatorAdd(
                    Op.Arr("c",[Op.ConstInt(0)]),
                    Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("b",[Op.Var("I")])])
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(!tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            for(iX in tracerEmitter.emitted) {
                Sys.println(switch(iX) {
                    case AccumulatorAdd(dest, source):
                    '${OpUtils.convToStr(dest)} += ${OpUtils.convToStr(source)}';
                    case Assign(dest, src):
                    '${OpUtils.convToStr(dest)} := ${OpUtils.convToStr(src)}';
                });
            }
        }

        { // gen code for a(I)*d(I,J)
            trace('-----');

            var tracerEmitter:TracerEmitter = new TracerEmitter();
            tracerEmitter.prgm = [
                Term.AccumulatorAdd(
                    Op.Arr("c",[Op.ConstInt(0)]),
                    Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("d",[Op.Var("I"), Op.Var("J")])])
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(!tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            for(iX in tracerEmitter.emitted) {
                Sys.println(switch(iX) {
                    case AccumulatorAdd(dest, source):
                    '${OpUtils.convToStr(dest)} += ${OpUtils.convToStr(source)}';
                    case Assign(dest, src):
                    '${OpUtils.convToStr(dest)} := ${OpUtils.convToStr(src)}';
                });
            }
        }

        { // gen code for a(I)*d(I,I)
            trace('-----');

            var tracerEmitter:TracerEmitter = new TracerEmitter();
            tracerEmitter.prgm = [
                Term.AccumulatorAdd(
                    Op.Arr("c",[Op.ConstInt(0)]),
                    Op.MulArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("d",[Op.Var("I"), Op.Var("I")])])
                ),
            ];
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(!tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            for(iX in tracerEmitter.emitted) {
                Sys.println(switch(iX) {
                    case AccumulatorAdd(dest, source):
                    '${OpUtils.convToStr(dest)} += ${OpUtils.convToStr(source)}';
                    case Assign(dest, src):
                    '${OpUtils.convToStr(dest)} := ${OpUtils.convToStr(src)}';
                });
            }
        }



        //commented because we can soon describe it
        //assigns.push( X.Assign(Op.Arr("r",0), Op.AddArr([Op.Arr("c", 0), Op.Arr("c", 1), Op.Arr("c", 2), Op.Arr("c", 3), Op.Arr("c", 4), Op.Arr("c", 5), Op.Arr("c", 6),Op.Arr("c", 7), Op.Arr("c", 8), ])) );
        


        //var target = new ConvertDynaToCode();
        //if(target.target == "haxe") Sys.println("class OutDyna0 {");
        //Sys.println(target.convAsFunction(assigns, "fn0")); // convert as function
        //if(target.target == "haxe") Sys.println("}");
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
    public static function unroll(x:Term, varFile:VarFile):Array<Term> {
        var resArr:Array<Term> = [];

        switch(x) {
            case Term.AccumulatorAdd(
                Op.Arr(arrNameDest, [Op.ConstInt(arrIdxDest)]),
                sourceOp/*Op.Arr(arrNameSource, Op.Var(arrVarSource))*/):
            
            // compute accessed (array) variables by variable name
            // ex: a(I)*b(I) -> I has array-vars [a, b]
            var arrayVarsByVariable = new Map<String, Array<String>>();
            retArrAccess(sourceOp, arrayVarsByVariable);

            { // debug content of arrayVarsByVariable
                for(iKey in arrayVarsByVariable.keys()) {
                    var varNames = arrayVarsByVariable[iKey];
                    trace('$iKey : $varNames');
                }
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
            function retRuleAccesses(op:Op): Array<{rule:String, params:Array<Op>}> {
                // is a recursive function
                var accesses = [];

                // internal helper function to collect result recursivly
                function internalRec(op:Op) {

                    switch(op) {
                        case Var(name):
                        case ConstFloat(val):
                        case ConstInt(val):
                        
                        case Arr(arrName, idxs): // ex: a(I)
                        accesses.push({rule:arrName, params:idxs});
                        
                        case AddArr(args):
                        for(iArg in args) internalRec(iArg);

                        case MulArr(args):
                        for(iArg in args) internalRec(iArg);

                        case Div(arg0, arg1):
                        internalRec(arg0);
                        internalRec(arg1);

                        case FnCall(name, args):
                        for(iArg in args) internalRec(iArg);

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
            
            var ruleAccesses:Array<{rule:String, params:Array<Op>}> = retRuleAccesses(sourceOp);

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
                var righthandSide:Op = sourceOp;
                
                for (iAssigmentVarName in varAssignment.assignments.keys()) {
                    var assignedIndex:Int = varAssignment.assignments.get(iAssigmentVarName); // the assigned index for the variable
                    var replaceOp:Op = Op.ConstInt(assignedIndex);// Op with which we substitute it
                    righthandSide = replaceVar(righthandSide, iAssigmentVarName, replaceOp);
                }
                
                return
                    Term.AccumulatorAdd(
                        Op.Arr(arrNameDest, [Op.ConstInt(arrIdxDest)]),
                        righthandSide);
            }
            
            // instantiate body of Rule for each variable assignment
            for (iVarAssignment in commonVarAssignments) {
                resArr.push(instantiateBodyWithVarAssigment(iVarAssignment));
            }



            case AccumulatorAdd(_,_):
            throw "Not recognized!"; // TODO

            /* TODO
            case Assign(dest, src):

            // compute accessed (array) variables by variable name
            // ex: a(I)*b(I) -> I has array-vars [a, b]
            var arrayVarsByVariable = new Map<String, Array<String>>();
            retArrAccess(src, arrayVarsByVariable);

            */


            case Assign(_,_):
            resArr.push(x);
        }

        return resArr;
    }

    // helper
    // replaces a variable with a actual value(index)
    private static function replaceVar(op:Op, varname:String, replace:Op): Op {
        switch(op) {
            case Var(name) if (name==varname):
            return replace; // replace

            case Arr(name, idxs):
            {
                var substIdxs = idxs.map(iIdx -> replaceVar(iIdx, varname, replace));
                return Arr(name, substIdxs);
            }

            case AddArr(args):
            return AddArr(args.map(iArg -> replaceVar(iArg, varname, replace)));

            case MulArr(args):
            return MulArr(args.map(iArg -> replaceVar(iArg, varname, replace)));

            case Div(arg0, arg1):
            return Div(replaceVar(arg0, varname, replace), replaceVar(arg1, varname, replace));

            case FnCall(name, args):
            return FnCall(name, args.map(iArg -> replaceVar(iArg, varname, replace)));

            case UnaryNeg(arg):
            return UnaryNeg(replaceVar(arg, varname, replace));

            case Trinary(cond, truePath, falsePath):
            return Trinary(replaceVar(cond, varname, replace), replaceVar(truePath, varname, replace), replaceVar(falsePath, varname, replace));

            case _:
            return op; // return without any change for all others
        }
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
            
            case Arr(arrName, idxs) if (hasOnlyVars(idxs)): // ex: a(I)            
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

            case AddArr(args):
            for(iArg in args) retArrAccess(iArg, res);

            case MulArr(args):
            for(iArg in args) retArrAccess(iArg, res);

            case Div(arg0, arg1):
            retArrAccess(arg0, res);
            retArrAccess(arg1, res);

            case FnCall(_, args):
            for(iArg in args) retArrAccess(iArg, res);

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

class Executive {
    public function new() {}

    // executes assignment
    public static function execAssign(assign:Term, varFile:VarFile) {
        switch (assign) {
            case Assign(dest, source):

            var val = calc(source, varFile);

            switch(dest) {
                case Arr(name, idxs):
                {
                    var indices:Array<Int> = idxs.map(iIdx -> Std.int(calc(iIdx, varFile))); // compute concrete indices

                    trace('access $name(${indices.map(v -> '$v').join(", ")})');
                    var idxStrKey:String = indices.map(v -> '$v').join("_"); // convert index to string key

    	            var arr:ArrObj = varFile.vars.get(name);
                    if (arr == null) {
                        arr = new ArrObj(idxs.length);
                        varFile.vars.set(name, arr);
                    }
                    varFile.vars.get(name).map.set(idxStrKey, val);
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

            case Arr(name, idxs):
            {
                var indices:Array<Int> = idxs.map(iIdx -> Std.int(calc(iIdx, varFile))); // compute concrete indices

                trace('access $name(${indices.map(v -> '$v').join(", ")})');
                var idxStrKey:String = indices.map(v -> '$v').join("_"); // convert index to string key
                return varFile.vars.get('$name').map.get(idxStrKey); // lookup in database
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

            case FnCall("exp",[arg]):
            return Math.exp(calc(arg, varFile));
            case FnCall("sqrt",[arg]):
            return Math.sqrt(calc(arg, varFile));
            case FnCall("abs",[arg]):
            return Math.abs(calc(arg, varFile));
            case FnCall("pow",[arg0,arg1]):
            return Math.pow(calc(arg0, varFile),calc(arg1, varFile));

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

// TODO< OpUtils to convert to string description >


enum Term {
    AccumulatorAdd(dest:Op, source:Op); // ex: b(I) += a(I)
    Assign(dest:Op, source:Op); // assignment: ex: b(0) := a(0)
}

// TODO< rename to Expr >
enum Op {
    Var(name:String); // variable access, ex: a(I), where I is the variable
    ConstFloat(val:Float);
    ConstInt(val:Int);
    Arr(name:String, idxs:Array<Op>); // array access, indices are for each dimension
    AddArr(args: Array<Op>);
    MulArr(args: Array<Op>);
    Div(arg0:Op, arg1:Op);

    FnCall(name:String, args:Array<Op>); // generalized function call

    UnaryNeg(arg: Op); // unary negation

    Trinary(cond: Op, truePath:Op, falsePath:Op); // trinary condition, cond is checked for >= 0.5

    // used for internal code generation
    TempVal(name:String); // access to temporary value
}

class OpUtils {
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

            case FnCall(name, args):
            return '$name(${args.map(iArg->convToStr(iArg))})';

            case UnaryNeg(arg):
            return "-"+convToStr(arg);

            case Trinary(cond, truePath, falsePath):
            return '((${convToStr(cond)}) >= 0.5 ? (${convToStr(truePath)}) : (${convToStr(falsePath)}))';

            case TempVal(name):
            return 'TEMP_$name';
        }
    }
}

// tracks open expressions because variables changed
class OpenTerm {
    // open Term's which need to get recomputed (in order)
    // value is the name/id of the Term
    public var open:Array<String> = [];

    public function new() {}
}

// tracer which tracks open Term's and emits linearized code
class TracerEmitter {
    public var emitted:Array<Term> = []; // emitted result code of tracing

    public var prgm:Array<Term> = []; // actual interpreted program

    // open set
    public var open:Array<Int> = []; // indices of open instructions to compute

    public var varFile:VarFile; // used varibale file

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
        emitted = emitted.concat(Unroller.unroll(term, varFile)); // emit execution

        return true; // continue
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
        if (indexConstraints.length != arr.width) {
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

        trace(varAssignments.length);
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

// associative array object
class ArrObj {
    // keys are strings of indices
    public var map:Map<String, Float> = new Map<String, Float>();

    public var width:Int;

    public function new(width) {
        this.width=width;
    }

    // helper to return all possible indices
    public function retIndices(): Array<Array<Int>> {
        var res:Array<Array<Int>> = [];

        for(iKey in map.keys()) {
            res.push(iKey.split("_").map(v -> Std.parseInt(v))); // split by "_" because we seperate indices with it
        }

        return res;
    }

    public static function create(arr:Array<Float>): ArrObj {
        var res = new ArrObj(1);
        for(iIdx in 0...arr.length) {
            res.map.set('$iIdx', arr[iIdx]);
        }
        return res;
    }

    // create two dimensional
    public static function create2(arr:Array<Array<Float>>): ArrObj {
        var res = new ArrObj(2);
        for(iIdx in 0...arr.length) {
            for(jIdx in 0...arr[iIdx].length) {
                res.map.set('${iIdx}_$jIdx', arr[iIdx][jIdx]);
            }
        }
        return res;
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
