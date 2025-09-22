package crowplexus.iris.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.Printer;
#end

using StringTools;

/**
 * @see https://github.com/th2l-devs/SScript/blob/main/src/hscriptBase/Tools.hx
 */
class StarClassesMacro {
	public static inline var thisName:String = "crowplexus.iris.Iris";

	public static function build() {
		trace("init star classes......");
		#if STAR_CLASSES
		Context.onGenerate(function(types) {
			trace(types);
			var names = [],
				self = TypeTools.getClass(Context.getType(thisName));

			for (t in types)
				switch t {
					case TInst(_.get() => c, _):
						var pack:String = c.pack.join(".").trim();
						if(!pack.startsWith("crowplexus.hscript")) {
							names.push(Context.makeExpr(pack != "" ? pack + "." + c.name : c.name, c.pos));
						}
					case TAbstract(_.get() => c, _):
						var pack:String = c.pack.join(".").trim();
						if(!pack.startsWith("crowplexus.hscript")) {
							names.push(Context.makeExpr(pack != "" ? pack + "." + c.name : c.name, c.pos));
						}
					default:
				}

			self.meta.remove('classes');
			self.meta.add('classes', names, self.pos);
		});
		#end
	}
}