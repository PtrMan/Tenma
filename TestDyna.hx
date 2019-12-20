// my own small Dyna inspired implementation
// tailored toward ML'ish puropses

// HANDLING:< handles one variable in add accumulation
//    ex: c(0) += a(I)*b(I) >

// TODO< handle two variable with assignment, ex >
// c(I) := a(I,J) * b(J)

// TODO< handle two variables with accumulator, ex >
// c(I) += a(I,J) * b(J)


// TODO< track open instructions in tracer correctly >

// TODO< handle two variables in codegen >





// TODO< support array based storage >
// TODO< decide when to choose which datastructure >

// TODO LATER< support min= aggregate >

// associative array object
class ArrObj {
    // keys are strings of indices
    public var map:Map<String, Float> = new Map<String, Float>();

    public function new() {}

    public static function create(arr:Array<Float>): ArrObj {
        var res = new ArrObj();
        for(iIdx in 0...arr.length) {
            res.map.set('$iIdx', arr[iIdx]);
        }
        return res;
    }
}

class TestDyna {
    public static function main() {
        UnittestUnroller.testOneVars2();
        UnittestUnroller.testTwoVars();
        
        var varFile:VarFile = new VarFile();
        varFile.vars.set("a", ArrObj.create([5.0, 2.0]));
        varFile.vars.set("b", ArrObj.create([0.11, 0.9]));

        varFile.vars.set("x", ArrObj.create([0.3]));




        // sigmoid activation
        // l(0) := 1.0/(1.0 + exp(-x(0)))
        var as1 = X.Assign(Op.Arr("l",[Op.ConstInt(0)]),   Op.Div(Op.ConstFloat(1.0), Op.AddArr([Op.ConstFloat(1.0), Op.Exp(Op.UnaryNeg(Op.Arr("x", [Op.ConstInt(0)])))]) ));
        Executive.execAssign(as1, varFile);

        // c(0) := a(0)*b(0) + l(0)
        var as0 = X.Assign(Op.Arr("c",[Op.ConstInt(0)]), Op.AddArr([Op.MulArr([Op.Arr("a", [Op.ConstInt(0)]), Op.Arr("b", [Op.ConstInt(0)])]), Op.Arr("l", [Op.ConstInt(0)])]));
        Executive.execAssign(as0, varFile);

        trace(varFile.vars.get("l").map.get("0"));
        trace(varFile.vars.get("c").map.get("0"));

        var assigns:Array<X> = [];

        { // test "unroll" mechanism
            var as2 = X.AccumulatorAdd(
                Op.Arr("c",[Op.ConstInt(0)]),
                Op.Arr("a",[Op.Var("I")])
            );

            assigns = assigns.concat(Unroller.unroll(as2, varFile));
        }


        for(i in 0...9) {
            assigns.push( X.Assign(Op.Arr("c",[Op.ConstInt(i)]), Op.MulArr([Op.Arr("a", [Op.ConstInt(0)]), Op.Arr("b", [Op.ConstInt(i)])])));
        }

        for(iX in assigns) {
            Sys.println(switch(iX) {
                case AccumulatorAdd(dest, source):
                '${OpUtils.convToStr(dest)} += ${OpUtils.convToStr(source)}';
                case Assign(dest, src):
                '${OpUtils.convToStr(dest)} := ${OpUtils.convToStr(src)}';
            });
        }

        trace('-----');

        var tracerEmitter:TracerEmitter = new TracerEmitter();
        tracerEmitter.prgm = [
            X.AccumulatorAdd(
                Op.Arr("c",[Op.ConstInt(0)]),
                Op.AddArr([Op.Arr("a",[Op.Var("I")]), Op.Arr("b",[Op.Var("I")])])
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
    public static function unroll(x:X, varFile:VarFile):Array<X> {
        var resArr:Array<X> = [];

        switch(x) {
            case X.AccumulatorAdd(
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

            var keysAsArr:Array<String> = [for (v in arrayVarsByVariable.keys()) v];
            if (keysAsArr.length != 1) {
                throw "more than one key is not handled!";
            }

            // names of arrays by current variable name
            var arrVarsByCurrentVar:Array<String> = arrayVarsByVariable.get(keysAsArr[0]);

            var indices = [];

            { // get indices of first variable
                var arrVarName = arrVarsByCurrentVar[0];
                var keysAsStr = varFile.vars.get(arrVarName).map.keys(); // get indices of array
                indices = [for (v in keysAsStr) Std.parseInt(v)]; // convert to integers
            }

            for(iVarIdx in 1...arrVarsByCurrentVar.length){ // intersect with other indices of other variables
                var arrVarName = arrVarsByCurrentVar[iVarIdx];
                var keysAsStr = varFile.vars.get(arrVarName).map.keys(); // get indices of array
                var indicesOfThisArr = [for (v in keysAsStr) Std.parseInt(v)]; // convert to integers
                indices = SetUtil.intersect(indices, indicesOfThisArr); // intersect because we can only use common indices
            }


            { // we need to allocate a new temporary value
                resArr.push( X.Assign(Op.TempVal("temp0_0"), Op.ConstFloat(0.0)) );
            }

            // unroll computation "loop"
            // TODO< replace variable by index >
            var idxCnt = 0; // used to name temporary variables
            for(iIdx in indices) {
                var replaceOp:Op = Op.ConstInt(iIdx);// Op with which we substitute it
                var varname:String = keysAsArr[0]; // substitute the only variable
                var righthandSide:Op = replaceVar(sourceOp, varname, replaceOp);

                var createdAssign =
                    X.Assign(
                        Op.TempVal('temp0_${idxCnt+1}'),
                        Op.AddArr([Op.TempVal('temp0_${idxCnt}'), righthandSide]));
                resArr.push(createdAssign);

                idxCnt++;
            }

            var createdAssign = X.Assign(
                Op.Arr(arrNameDest, [Op.ConstInt(arrIdxDest)]),
                Op.TempVal('temp0_${idxCnt+1}')
            );
            resArr.push(createdAssign);

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

            case Exp(arg):
            return Exp(replaceVar(arg, varname, replace));

            case Sqrt(arg):
            return Sqrt(replaceVar(arg, varname, replace));

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

            case Exp(arg):
            retArrAccess(arg, res);

            case Sqrt(arg):
            retArrAccess(arg, res);

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
    public static function execAssign(assign:X, varFile:VarFile) {
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
                        arr = new ArrObj();
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

            case Exp(arg):
            return Math.exp(calc(arg, varFile));

            case Sqrt(arg):
            return Math.sqrt(calc(arg, varFile));

            case UnaryNeg(arg):
            return -calc(arg, varFile);

            case Trinary(cond, truePath, falsePath):
            return (calc(cond, varFile) >= 0.5 ? calc(truePath, varFile) : calc(falsePath, varFile));

            case TempVal(name):
            throw "Not implemented!!";
        }
    }
}

// TODO< OpUtils to convert to string description >


// TODO< name >
enum X {
    AccumulatorAdd(dest:Op, source:Op); // ex: b(I) += a(I)
    Assign(dest:Op, source:Op); // assignment: ex: b(0) := a(0)
}

enum Op {
    Var(name:String); // variable access, ex: a(I), where I is the variable
    ConstFloat(val:Float);
    ConstInt(val:Int);
    Arr(name:String, idxs:Array<Op>); // array access, indices are for each dimension
    AddArr(args: Array<Op>);
    MulArr(args: Array<Op>);
    Div(arg0:Op, arg1:Op);

    Exp(arg: Op);
    Sqrt(arg: Op);

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

            case Exp(arg):
            return 'exp(${convToStr(arg)})';

            case Sqrt(arg):
            return 'sqrt(${convToStr(arg)})';

            case UnaryNeg(arg):
            return "-"+convToStr(arg);

            case Trinary(cond, truePath, falsePath):
            return '((${convToStr(cond)}) >= 0.5 ? (${convToStr(truePath)}) : (${convToStr(falsePath)}))';

            case TempVal(name):
            return 'TEMP_$name';
        }
    }
}

/*
// converter to convert dyna to haxe
class ConvertDynaToCode {
    //public var tempCounter:Int = 0; // used to allocate temp values

    //public var lines:Array<String> = []; // emitted lines

    // target can be "haxe" or "cuda"
    public var target:String = "cuda";

    public function new() {}

    public function convOp(op:Op):String {
        switch(op) {
            case Var(name):
            throw "Not implemented";
            case ConstFloat(val):
            return '$val';
            case ConstInt(val):
            return '$val';

            case Arr(name, idx):
            if (target == "haxe") {
                return "ctx.vars.get("+'${name}__$idx'+")"; // lookup in database
            }
            else {
                return 'ctx->${name}__$idx'; // statically reference because GPU doesn't support lookup, and lookup is to slow
            }

            case AddArr(args):
            {
                var resArr:Array<String> = args.map(iArg -> convOp(iArg));
                return "(" + resArr.join(" + ") + ")";
            }

            case MulArr(args):
            {
                var resArr:Array<String> = args.map(iArg -> convOp(iArg));
                return "(" + resArr.join(" * ") + ")";
            }

            case Div(arg0, arg1):
            return "("+convOp(arg0)+"/"+convOp(arg1)+")";

            case Exp(arg):
            if (target == "haxe") {
                return 'Math.exp(${convOp(arg)})';
            }
            else {
                return 'exp(${convOp(arg)})';
            }

            case UnaryNeg(arg):
            return "-"+convOp(arg);

            case Trinary(cond, truePath, falsePath):
            return '((${convOp(cond)}) >= 0.5 ? (${convOp(truePath)}) : (${convOp(falsePath)}))';

            case TempVal(name):
            throw "Not implemented!!";
        }
    }

    public function convAssign(assign:X): String {
        switch (assign) {
            case Assign(dest, source):
            switch(dest) {
                case Arr(name, idx):
                if (target == "haxe") {
                    return "ctx.vars.set("+'${name}__$idx, ${convOp(source)});';
                }
                else {
                    return 'ctx->${name}__$idx = ${convOp(source)};'; // static reference
                }

                case _:
                throw "Expected Arr!";
            }
            
            case _:
            throw "Not implemented!";
        }
    }

    // returns the string of a function which executes a series of assigns statically
    public function convAsFunction(assigns:Array<X>, name:String): String {
        var res = "";
        if (target == "haxe") res='public static function $name(ctx:Propagate) {\n';
        else if(target == "cuda") res='__device__ void $name(Propagate *ctx) {\n';

        res += [for (i in assigns) convAssign(i)].join("\n");
        res += "\n}";
        return res;
    }
}
*/

// tracks open expressions because variables changed
class OpenX {
    // open X's which need to get recomputed (in order)
    // value is the name/id of the X
    public var open:Array<String> = [];

    public function new() {}
}

// tracer which tracks open X's and emits linearized code
class TracerEmitter {
    public var emitted:Array<X> = []; // emitted result code of tracing

    public var prgm:Array<X> = []; // actual interpreted program

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
        
        var instr:X = prgm[currentOpen]; // fetch instruction
        emitted = emitted.concat(Unroller.unroll(instr, varFile)); // emit execution

        return true; // continue
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