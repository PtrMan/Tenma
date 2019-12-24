/*
Copyright 2019 Robert Wünsche

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

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

                // definition of sigmoid activation
                // sigmoid(X) := 1.0/(1.0 + exp(-X)).
                Term.Equal(Op.Arr("sigmoid",[Op.Var("X")]),   [Op.Div(Op.ConstFloat(1.0), Op.AddArr([Op.ConstFloat(1.0), Op.Arr("exp", [Op.UnaryNeg(Op.Var("X"))])]) )]),
                
                // definition of relu activation
                // relu(X) := max(X, 0.0).
                Term.Equal(Op.Arr("relu",[Op.Var("X")]),   [Op.Arr("max", [Op.Var("X"),Op.ConstFloat(0.0)])]),
        

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
            codegen.target = "cuda";

            var emitted = convAsClassWithFunctions([{terms:tracerEmitter.emitted, name:"fn0"}] , varFile);
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