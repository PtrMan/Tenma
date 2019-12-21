package dyna;

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

    public function convAssign(assign:Term): String {
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
