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