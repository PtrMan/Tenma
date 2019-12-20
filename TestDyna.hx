// my own small Dyna inspired implementation
// tailored toward ML'ish puropses

// TODO< handle a(I)*b(I) >

// TODO< refactor set or variables to associative array by array name >
// TODO< track open variables >
// TODO< tracer which tracks open variables and emits "linearized" code >

// c(0) += a(I)*b(I)

class TestDyna {
    public static function main() {
        var p:Propagate = new Propagate();
        p.vars.set("a__0", 5.0);
        p.vars.set("a__1", 2.0);

        p.vars.set("b__0", 0.11);
        p.vars.set("b__1", 0.9);

        p.vars.set("x__0", 0.3);

        // sigmoid activation
        // l(0) := 1.0/(1.0 + exp(-x(0)))
        var as1 = X.Assign(Op.Arr("l",Op.ConstInt(0)),   Op.Div(Op.ConstFloat(1.0), Op.AddArr([Op.ConstFloat(1.0), Op.Exp(Op.UnaryNeg(Op.Arr("x", Op.ConstInt(0))))]) ));
        p.execAssign(as1);

        // c(0) := a(0)*b(0) + l(0)
        var as0 = X.Assign(Op.Arr("c",Op.ConstInt(0)), Op.AddArr([Op.MulArr([Op.Arr("a", Op.ConstInt(0)), Op.Arr("b", Op.ConstInt(0))]), Op.Arr("l", Op.ConstInt(0))]));
        p.execAssign(as0);

        trace(p.vars.get("l__0"));
        trace(p.vars.get("c__0"));

        var assigns:Array<X> = [];

        { // test "unroll" mechanism
            var as2 = X.AccumulatorAdd(
                Op.Arr("c",Op.ConstInt(0)),
                Op.Arr("d",Op.Var("I"))
            );

            assigns = assigns.concat(Unroller.unroll(as2));
        }


        for(i in 0...9) {
            assigns.push( X.Assign(Op.Arr("c",Op.ConstInt(i)), Op.MulArr([Op.Arr("a", Op.ConstInt(0)), Op.Arr("b", Op.ConstInt(i))])));
        }

        for(iX in assigns) {
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

// unrolls a(0) += b(J)  to a(0) += b(0), a(0) += b(1), etc.
class Unroller {
    // TODO< provide context
    public static function unroll(x:X):Array<X> {
        var resArr:Array<X> = [];

        switch(x) {
            // TODO< handle more cases >
            case X.AccumulatorAdd(
                Op.Arr(arrNameDest, Op.ConstInt(arrIdxDest)),
                Op.Arr(arrNameSource, Op.Var(arrVarSource))):

            var indices = [0,1,2]; // TODO< enumerate and filter >
            
            { // we need to allocate a new temporary value
                resArr.push( X.Assign(Op.TempVal("temp0_0"), Op.ConstFloat(0.0)) );
            }

            // unroll computation "loop"
            var idxCnt = 0; // used to name temporary variables
            for(iIdx in indices) {
                var createdAssign =
                    X.Assign(
                        Op.TempVal('temp0_${idxCnt+1}'),
                        Op.AddArr([Op.TempVal('temp0_${idxCnt}'), Op.Arr(arrNameSource, Op.ConstInt(iIdx))]));
                resArr.push(createdAssign);

                idxCnt++;
            }

            var createdAssign = X.Assign(
                Op.Arr(arrNameDest, Op.ConstInt(arrIdxDest)),
                Op.TempVal('temp0_${idxCnt+1}')
            );
            resArr.push(createdAssign);

            case AccumulatorAdd(_,_):
            throw "Not recognized!"; // TODO

            case Assign(_,_):
            resArr.push(x);
        }

        return resArr;
    }
}

// a[0] + a[1] + a[2]
class Propagate {
    // register file
    public var vars:Map<String, Float> = new Map<String, Float>();

    public function new() {}

    // executes assignment
    public function execAssign(assign:X) {
        switch (assign) {
            case Assign(dest, source):

            var val = calc(source);

            switch(dest) {
                case Arr(name, idx):
                {
                    var idx2 = Std.int(calc(idx));
                    vars.set('${name}__$idx2', val);
                }

                case _:
                throw "Expected Arr!";
            }

            case _:
            throw "Not implemented!";
        }
    }

    public function calc(op:Op): Float {
        switch(op) {
            case Var(name):
            throw "Not implemented!";
            case ConstFloat(val):
            return val;
            case ConstInt(val):
            return val;

            case Arr(name, idx):
            {
                var temp:Float;
                temp = calc(idx);

                trace('${name}__${Std.int(temp)}');
                return vars.get('${name}__${Std.int(temp)}'); // lookup in database

            }

            case AddArr(args):
            {
                var resArr:Array<Float> = args.map(iArg -> calc(iArg));
                var res=0.0;
                for(iRes in resArr) {
                    res+=iRes;
                }
                return res;
            }

            case MulArr(args):
            {
                var resArr:Array<Float> = args.map(iArg -> calc(iArg));
                var res=1.0;
                for(iRes in resArr) {
                    res*=iRes;
                }
                return res;
            }

            case Div(arg0, arg1):
            return calc(arg0)/calc(arg1);

            case Exp(arg):
            return Math.exp(calc(arg));

            case UnaryNeg(arg):
            return -calc(arg);

            case Trinary(cond, truePath, falsePath):
            return (calc(cond) >= 0.5 ? calc(truePath) : calc(falsePath));

            case TempVal(name):
            throw "Not implemented!!";
        }
    }
}

// TODO< OpUtils to convert to string description >

/*
class Assign {
    public var source: Op;
    public var dest: Op;
    public function new(dest, source) {
        this.dest = dest;
        this.source = source;
    }
}
*/

// TODO< name >
enum X {
    AccumulatorAdd(dest:Op, source:Op); // ex: b(I) += a(I)
    Assign(dest:Op, source:Op); // assignment: ex: b(0) := a(0)
}

enum Op {
    Var(name:String); // variable access, ex: a(I), where I is the variable
    ConstFloat(val:Float);
    ConstInt(val:Int);
    Arr(name:String, idx:Op);
    AddArr(args: Array<Op>);
    MulArr(args: Array<Op>);
    Div(arg0:Op, arg1:Op);
    Exp(arg: Op);

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


            case Arr(name, idx):
            return '$name(${convToStr(idx)})';
            
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
