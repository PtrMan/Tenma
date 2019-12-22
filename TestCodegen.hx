import sys.io.File;
import sys.FileSystem;

import dyna.Dyna;
import dyna.ConvertDynaToCode;

// test codegeneration
class TestCodegen {
    public static function main() {
        var varFile:VarFile = new VarFile();
        varFile.vars.set("w", ArrObj.create2([[0.3, 0.1, 0.2], [0.3, 0.1, 0.2], [0.3, 0.1, 0.2], [0.3, 0.1, 0.2]])); // weights
        varFile.vars.set("i", ArrObj.create([0.3, 0.1, 0.9, 0.1])); // input

        varFile.vars.set("bias0", ArrObj.create([0.0, 0.0, 0.0, 0.0])); // bias values

        varFile.vars.set("t0", ArrObj.create([0.0, 0.0, 0.0, 0.0]));
        varFile.vars.set("t", ArrObj.create([0.0, 0.0, 0.0, 0.0]));


        varFile.vars.set("l", ArrObj.create([0.0, 0.0, 0.0, 0.0]));

        { // program with complex activation function
            trace('-----');

            var ePow2x = Op.Arr("exp", [Op.MulArr([Op.ConstFloat(2.0), Op.Var("Q")])]);

            var prgm = [
                // definition of tanh
                Term.Equal(
                    Op.Arr("tanh",[Op.Var("Q")]),
                    [Op.Div(Op.AddArr([ePow2x, Op.ConstFloat(-1.0)]), Op.AddArr([ePow2x, Op.ConstFloat(1.0)]))] // l(i) := (e^(2Q) - 1)/(e^(2Q) + 1)
                ),

                // matrix mul
                Term.Assign(Aggregation.ADD,Op.Arr("t0",[Op.Var("I")]),   [Op.MulArr([Op.Arr("i", [Op.Var("I")]), Op.Arr("w", [Op.Var("I"), Op.Var("J")])])]),
                
                // add bias
                Term.Assign(Aggregation.NONE,Op.Arr("t",[Op.Var("I")]),   [Op.AddArr([Op.Arr("t0", [Op.Var("I")]), Op.Arr("bias0", [Op.Var("I")])])]),


                Term.Assign(Aggregation.NONE,Op.Arr("l",[Op.Var("I")]),   [Op.Arr("tanh", [Op.Arr("t", [Op.Var("I")])])]), // l(I) := tanh(t(I)).
            ];

            var tracerEmitter:LinearStrategy = new LinearStrategy();
            tracerEmitter.prgm = prgm;
            tracerEmitter.varFile = varFile;
            tracerEmitter.reopen();

            while(tracerEmitter.traceStep()) { // trace until program terminates
            }

            // debug emitted program
            Sys.println(PrgmUtils.convToStr(tracerEmitter.emitted));



            trace("---");
            // emit code and print
            var codegen = new ConvertDynaToCode();
            codegen.target = "haxe";

            var emitted = "";
            emitted += "import dyna.HaxeRuntime;\n";
            emitted += "class Out0 {\n";
            emitted += codegen.convAsFunction(tracerEmitter.emitted, "fn0", varFile);
            emitted += "}\n";

            Sys.println(emitted);

            { // store emitted code
                /*try*/ {
                    FileSystem.deleteFile("Out0.hx"); // delete old file
                }
                
                
                /*try*/ {
                    var f = File.append("Out0.hx");
                    f.writeString(emitted);
                    f.flush();
                    f.close();
                }
            }
        }
    }
}