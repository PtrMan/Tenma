/*
Copyright 2019 Robert Wünsche

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import dyna.Dyna;

// invokes generated code
class TestInvokeOut0 {
    public static function main() {
        // need to init VarFile with right size(s)
        var varFile:VarFile = new VarFile();
        varFile.vars.set("w", ArrObj.create2([[0.3, 0.1, 0.2], [0.3, 0.1, 0.2], [0.3, 0.1, 0.2], [0.3, 0.1, 0.2]])); // weights
        varFile.vars.set("i", ArrObj.create([0.3, 0.1, 0.9, 0.1])); // input

        varFile.vars.set("bias0", ArrObj.create([0.0, 0.0, 0.0, 0.0])); // bias values

        varFile.vars.set("t0", ArrObj.create([0.0, 0.0, 0.0, 0.0]));
        varFile.vars.set("t", ArrObj.create([0.0, 0.0, 0.0, 0.0]));

        varFile.vars.set("l", ArrObj.create([0.0, 0.0, 0.0, 0.0]));
        
        Out0.fn0(varFile);

        var arrL = varFile.vars.get("l"); // get result array
        // print results
        for(iv in arrL.dense) {
            Sys.println('$iv');
        }
    }
}