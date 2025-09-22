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
	public static inline var thisName:String = "crowplexus.iris.macro.StarClassesMacro";

	macro static function build() {
		#if (macro && !display)
		Context.onGenerate(function(types) {
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
		return macro cast haxe.rtti.Meta.getType($p{thisName.split('.')});
		#else
		return macro cast {classes: ([]: Array<String>)};
		#end
	}

	#if !macro
	public static final packageClasses:Map<String, Array<{var name:String; var value:Dynamic;}>> = {
		function returnMap() {
			var r:Array<String> = build().classes;
			var map = new Map<String, Array<{var name:String; var value:Dynamic;}>>();

			for (i in r) {
				final lastIndex = i.lastIndexOf(".");
				final pack = lastIndex > -1 ? i.substr(0, lastIndex) : "";
				final lastName = i.substr(lastIndex > -1 ? lastIndex + 1 : 0);

				if (lastIndex > -1 && i.indexOf('_Impl_') == -1 && pack.trim() != "")
				{
					var c = crowplexus.iris.Iris.proxyImports.get(i) ?? Type.resolveClass(i);
					if (c != null) {
						if(!map.exists(pack)) map.set(pack, []);
						map[pack].push({name: lastName, value: c});
					}
				}
			}

			return map;
		}
		returnMap();
	}
	#end
}