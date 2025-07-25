package;

import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Printer;

class HScript extends Iris {
	public var path:String;

	public function new(path:String, autoRun:Bool = false) {
		this.path = path;
		var sc:Null<String> = Assets.getScript(this.path);
		if(sc == null) {
			sc = "";
			Iris.error("Loading this script failed as invalid path -> " + this.path);
		}
		super(sc, new IrisConfig(path, autoRun, false));
	}
}