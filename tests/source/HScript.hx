package;

import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Printer;

class HScript extends Iris {
	public var path:String;

	public function new(path:String, allowEnum:Bool = false, allowClass:Bool = false, experimental_features:Bool = false) {
		this.path = path;
		var sc:Null<String> = Assets.getScript(this.path);
		if(sc == null) {
			sc = "";
			Iris.error("Loading this script failed as invalid path -> " + this.path);
		}
		super(sc, new IrisConfig(path, allowEnum, allowClass, false, false));
		if(experimental_features) {
			this.parser.allowInterpolation = true;
		}
	}
}