package crowplexus.hscript.scriptenum;

import crowplexus.hscript.Expr;

class ScriptEnum implements crowplexus.hscript.ISharedScript {
	public var name:String;
	public var fullPath(get, never):String;
	@:dox(hide) inline function get_fullPath():String {
		if(packages != null && packages.length > 0) {
			return packages.join(".") + "." + name;
		}
		return name;
	}
	public var packages:Array<String>;

	@:allow(crowplexus.hscript.Interp)
	var sm:Map<String, Dynamic> = [];

	public function new(name:String, ?packages:Array<String>) {
		this.name = name;
		this.packages = packages;
	}

	public function hget(id:String, ?expr:Expr):Dynamic {
		if(!sm.exists(id))
		#if hscriptPos
		throw if(expr != null) {
			new Error(ECustom("ScriptEnum -> '" + name + "' Has Not EnumValue -> '" + id + "'"), expr.pmin, expr.pmax, expr.origin, expr.line);
		} else {
			new Error(ECustom("ScriptEnum -> '" + name + "' Has Not EnumValue -> '" + id + "'"), 0, 0, "hscript", 0);
		}
		#else
			throw ECustom("ScriptEnum -> '" + name + "' Has Not EnumValue -> '" + id + "'")
		#end
		return sm.get(id);
	}

	public function hset(name:String, value:Dynamic, ?expr:Expr):Void {
		#if hscriptPos
		throw if(expr != null) {
			new Error(ECustom("Cannot Set-up EnumValue"), expr.pmin, expr.pmax, expr.origin, expr.line);
		} else {
			new Error(ECustom("Cannot Set-up EnumValue"), 0, 0, "hscript", 0);
		}
		#else
			throw ECustom("Cannot Set-up EnumValue");
		#end
	}
}