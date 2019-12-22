package dyna;

// converter to convert dyna to haxe
class ConvertDynaToCode {
    //public var tempCounter:Int = 0; // used to allocate temp values

    // target can be "haxe" or "cuda"
    public var target:String = "haxe";

    public function new() {}

    public function convOp(expr:Dyna.Op, varFile:Dyna.VarFile):String {
        switch(expr) {
            case Var(name):
            throw "Not implemented";
            case ConstFloat(val):
            return '$val';
            case ConstInt(val):
            return '$val';


            
            case Arr(fnName, args) if (["exp","sqrt","abs","pow","cos","sin","min","max"].filter(iv -> iv == fnName).length > 0):
            if (target == "haxe") {
                return 'Math.$fnName(${args.map(iArg -> convOp(iArg, varFile)).join(", ")})';
            }
            else if(target == "cuda") {
                return '$fnName(${args.map(iArg -> convOp(iArg, varFile)).join(", ")})';
            }
            else {
                throw 'Not supported target $target!';
            }

            case Arr(name, idxs):
            // convert index to "key"-string for hashmap
            var staticKey:String = calcStaticKeyForArrAccess(expr);
            var arr:Dyna.ArrObj = varFile.vars.get(name);
            var staticIdxs:Array<Int> = calcStaticIdxsForArrAccess(expr); // statically compute access indices

            if (target == "haxe") {
                if (arr.isDense()) {
                    if (arr.dim == 1) return 'ctx.vars.get("$name").dense[$staticKey]';
                    else if (arr.dim == 2) return 'ctx.vars.get("$name").denseAt2(${staticIdxs[0]},${staticIdxs[1]})';
                    else throw 'Not implemented for ${arr.dim} dimension arr access!';
                }
                else {
                    return 'ctx.vars.get("$name").map.get("$staticKey")'; // lookup in database
                }
            }
            else if(target == "cuda") {
                if (arr.isDense()) {
                    throw "dense path for cuda is not implemented!"; // TODO
                }
                else {
                    return 'ctx->${name}__$staticKey'; // statically reference because GPU doesn't support lookup, and lookup is to slow
                }
            }
            else throw 'Arr not implemented for target "$target"';
            

            case AddArr(args):
            {
                var resArr:Array<String> = args.map(iArg -> convOp(iArg, varFile));
                return "(" + resArr.join(" + ") + ")";
            }

            case MulArr(args):
            {
                var resArr:Array<String> = args.map(iArg -> convOp(iArg, varFile));
                return "(" + resArr.join(" * ") + ")";
            }

            case Div(arg0, arg1):
            return "("+convOp(arg0, varFile)+"/"+convOp(arg1, varFile)+")";

            case UnaryNeg(arg):
            return "-"+convOp(arg, varFile);

            case Trinary(cond, truePath, falsePath):
            return '((${convOp(cond, varFile)}) >= 0.5 ? (${convOp(truePath, varFile)}) : (${convOp(falsePath, varFile)}))';

            case TempVal(name):
            throw "Not implemented!!";
        }
    }

    public function convTerm(term:Dyna.Term, varFile:Dyna.VarFile): String {
        switch (term) {
            case Assign(aggr, dest, source):
            
            switch(dest) {
                case Arr(name, idxs):
                // convert index to "key"-string for hashmap
                var staticKey:String = calcStaticKeyForArrAccess(dest);
                var arr:Dyna.ArrObj = varFile.vars.get(name);
                var staticIdxs:Array<Int> = calcStaticIdxsForArrAccess(dest); // statically compute access indices
                
                if (target == "haxe") {
                    if (arr.isDense()) {
                        if (arr.dim == 1) {
                            switch (aggr) {
                                case NONE: return 'ctx.vars.get("$name").dense[${staticIdxs[0]}] = ${convOp(source, varFile)};';
                                case ADD: return 'ctx.vars.get("$name").dense[${staticIdxs[0]}] += ${convOp(source, varFile)};';
                                case MIN: return 'ctx.vars.get("$name").dense[${staticIdxs[0]}] = Math.min(ctx.vars.get("$name").dense[${staticIdxs[0]}], ${convOp(source, varFile)});';
                                case MAX: return 'ctx.vars.get("$name").dense[${staticIdxs[0]}] = Math.max(ctx.vars.get("$name").dense[${staticIdxs[0]}], ${convOp(source, varFile)});';
                            }
                        }
                        else if(arr.dim == 2) {
                            switch (aggr) {
                                case NONE: return 'ctx.vars.get("$name").denseSetAt2(${staticIdxs[0]}, ${staticIdxs[1]}, ${convOp(source, varFile)});';
                                case ADD: return 'HaxeRuntime.aggrAddDense2(ctx.vars.get("$name"), ${staticIdxs[0]}, ${staticIdxs[1]}, ${convOp(source, varFile)});';
                                case MIN: throw "not implemented!";
                                case MAX: throw "not implemented!"; 
                            }
                        }
                        else {
                            throw "not supported array dimension for dense access!";
                        }
                    }
                    else {
                        switch (aggr) {
                            case NONE: return 'ctx.vars.get("$name").map.set("$staticKey", ${convOp(source, varFile)});';
                            case ADD: return 'HaxeRuntime.aggrAddSparse(ctx.vars.get("$name"), "$staticKey", ${convOp(source, varFile)});';
                            case MIN: return 'HaxeRuntime.aggrMinSparse(ctx.vars.get("$name"), "$staticKey", ${convOp(source, varFile)});';
                            case MAX: return 'HaxeRuntime.aggrMaxSparse(ctx.vars.get("$name"), "$staticKey", ${convOp(source, varFile)});';
                        }
                    }
                }
                else if(target=="cuda"){
                    throw "not implemented!";
                    /* old untested code for sparse access
                    switch (aggr) {
                        case NONE: return 'ctx->${name}__$staticKey = ${convOp(source, varFile)};'; // static reference
                        case ADD: return 'ctx->${name}__$staticKey = aggrAddSparse(ctx->${name}__$staticKey, ${convOp(source, varFile)});';
                        case MIN: return 'ctx->${name}__$staticKey = aggrMinSparse(ctx->${name}__$staticKey, ${convOp(source, varFile)});';
                        case MAX: return 'ctx->${name}__$staticKey = aggrMaxSparse(ctx->${name}__$staticKey, ${convOp(source, varFile)});';
                    } */
                }
                else {
                    throw 'Assign not supported for target "$target"';
                }

                case _:
                throw "Expected Arr!";
            }
            
            return "TODO";
            
            case _:
            throw "Not implemented!";
        }
    }
    
    // convert index to "key"-string for hashmap
    private static function calcStaticKeyForArrAccess(expr:Dyna.Op): String {
        return calcStaticIdxsForArrAccess(expr).map(iIdx -> '$iIdx').join("_");
    }

    // convert indices to actual index arr
    private static function calcStaticIdxsForArrAccess(expr:Dyna.Op): Array<Int> {
        return switch(expr) {
            case Arr(name, idxs):
            idxs.map(iIdx -> {
                switch(iIdx) {
                    case Dyna.Op.ConstInt(v): v;
                    case _: throw "Not supported index computation!";
                }
            });
            
            case _:
            throw "Expected Arr";
        }
    }

    // returns the string of a function which executes a series of assigns statically
    public function convAsFunction(terms:Array<Dyna.Term>, name:String, varFile:Dyna.VarFile): String {
        var res = "";
        if (target == "haxe") res='public static function $name(ctx:dyna.Dyna.VarFile) {\n';
        else if(target == "cuda") res='__device__ void $name(VarFile *ctx) {\n';
        else throw 'function not supported for target "$target"';

        res += [for (i in terms) convTerm(i, varFile)].join("\n");
        res += "\n}";
        return res;
    }
}
