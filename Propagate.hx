// my own small Dyna inspired implementation
// tailored toward ML'ish puropses

class TestDyna {
    public static function main() {
        var p:Propagate = new Propagate();
        trace( p.calc(Op.AddArr([Op.Arr("a", 0), Op.Arr("a", 1)]) );
    }
}

// b[0] := a[0] + a[1] + a[2]
class Propagate {
    public function new() {}

    public function calc(op:Op): Float {
        switch(op) {
            case Arr(name, idx):
            // TODO< lookup current value in database >
            return 1.0; 

            case AddArr(args):
            {
                var resArr:Array<Float> = args.map(iArg -> calc(iArg));
                var res=0.0;
                for(iRes in resArr) {
                    res+=iRes;
                }
                return res;
            }
        }
    }
}

// assignment: ex: b[0] := a[0]
class Assign {
    public var source: Op;
    public var dest: Op;
    public function new(dest, source) {
        this.dest = dest;
        this.source = source;
    }
}

enum Op {
    Arr(name:String, idx:Int);
    AddArr(args: Array<Op>);
}