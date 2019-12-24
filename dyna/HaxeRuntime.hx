/*
Copyright 2019 Robert Wünsche

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
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
