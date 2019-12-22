package dyna;

// haxe runtime for dyna
// contains static methods which are called from generated code
class HaxeRuntime {
    // add to dense 1d array
    public static function aggrAddDense1(arr:Dyna.ArrObj, idx:Int, v:Float) {
        arr.dense[idx] = arr.dense[idx] + v;
    }

    // add to dense 2d array
    public static function aggrAddDense2(arr:Dyna.ArrObj, y:Int, x:Int, v:Float) {
        var v2 = arr.denseAt2(y,x) + v;
        arr.denseSetAt2(y,x,v2);
    }

    // aggregate add
    public static function aggrAddSparse(arr:Dyna.ArrObj, staticKey:String, valSource:Float) {
        var value = arr.map.get(staticKey) + valSource;
        arr.map.set(staticKey, value);
    }

    // aggregate min
    public static function aggrMinSparse(arr:Dyna.ArrObj, staticKey:String, valSource:Float) {
        var value = Math.min(arr.map.get(staticKey), valSource);
        arr.map.set(staticKey, value);
    }

    // aggregate max
    public static function aggrMaxSparse(arr:Dyna.ArrObj, staticKey:String, valSource:Float) {
        var value = Math.max(arr.map.get(staticKey), valSource);
        arr.map.set(staticKey, value);
    }
}
