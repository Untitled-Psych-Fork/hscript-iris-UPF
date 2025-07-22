package crowplexus.hscript;

interface IScriptReadable {
	public function sc_exists(name:String):Bool;
	public function sc_get(name:String):Dynamic;
	public function sc_set(name:String, value:Dynamic):Void;
	public function sc_call(name:String, ?args:Array<Dynamic>):Dynamic;
}