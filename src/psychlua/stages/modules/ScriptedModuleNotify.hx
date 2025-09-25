package psychlua.stages.modules;

import haxe.io.Path;
import crowplexus.iris.Iris;
import crowplexus.hscript.Printer;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Interp;

import sys.FileSystem;
import sys.io.File;

using StringTools;

@:allow(psychlua.stages.modules.ModuleAgency)
class ScriptedModuleNotify {
	private static var _classPaths:Array<String>;
	private static var _includeExt:Array<String> = ["hx"];
	private static var _specifyClasses:Array<Class<Dynamic>>;
	private static var _specifyClassFullPaths:Array<String>;
	private static var _specifyClassNames:Array<String>;

	public static var classSystems:Map<String, Array<ModuleAgency>> = [];
	public static var unpackModules:Array<ModuleAgency> = [];

	private static var unpackUnusedClasses:Map<String, {var m:ModuleAgency; var e:Expr;}> = [];

	public static function init(specifyClasses:Array<Class<Dynamic>>, classPaths:Array<String>, ?includeExtension:Array<String>) {
		Interp.clearCache();
		errored = false;

		ScriptedModuleNotify._classPaths = classPaths;
		if(includeExtension != null) ScriptedModuleNotify._includeExt = includeExtension;
		ScriptedModuleNotify._specifyClasses = specifyClasses;
		ScriptedModuleNotify._specifyClassFullPaths = [];
		ScriptedModuleNotify._specifyClassNames = [];
		for(_specifyClass in ScriptedModuleNotify._specifyClasses) {
			var _specifyClassFullPath = Type.getClassName(_specifyClass);
			final last = _specifyClassFullPath.lastIndexOf(".");
			var _specifyClassName = _specifyClassFullPath.substr(last > -1 ? last + 1 : 0);
			ScriptedModuleNotify._specifyClassFullPaths.push(_specifyClassFullPath);
			ScriptedModuleNotify._specifyClassNames.push(_specifyClassName);
		}

		classSystems = new Map();
		unpackUnusedClasses = new Map();
		unpackModules = [];
		for(cp in ScriptedModuleNotify._classPaths) {
			_forceClassPath = cp;
			getFiles(cp);
			_forceClassPath = null;
		}
		execute();
	}

	private static function execute() {
		for(v in unpackModules) {
			v.execute();
		}
		for(ms in classSystems) {
			for(v in ms) v.execute();
		}
	}

	static var _forceClassPath:Null<String>;

	private static function getFiles(cp:String) {
		if(FileSystem.exists(cp) && FileSystem.isDirectory(cp)) {
			for(file in FileSystem.readDirectory(cp)) {
				final path = Path.addTrailingSlash(cp) + file;
				if(FileSystem.isDirectory(path)) {
					getFiles(path);
				} else if(_includeExt.contains(Path.extension(file))) {

					final saved = _forceClassPath.length + 1;
					final origin = "(" + _forceClassPath + ")" + path.replace(_forceClassPath, "src");
					var rp = if(saved < path.lastIndexOf("/")) path.substring(saved, path.lastIndexOf("/")).replace("/", ".") else "";

					final p = parse(path, origin, rp);
					if(p != null) {
						if(!classSystems.exists(rp) && rp != "") classSystems[rp] = [];
						final module = new ModuleAgency(p, rp, origin);
						(if(rp != "") classSystems[rp] else unpackModules).push(module);
					}
				}
			}
		}
	}

	private static var errored:Bool = false;
	static function parse(path:String, origin:String, rp:String):Expr {
		if(!errored) {
			var code:Null<String> = try File.getContent(path) catch(e) null;
			if(code != null) {
				var parser = new Parser();
				parser.allowTypes = parser.allowMetadata = parser.allowJSON = parser.allowInterpolation = true;
				var e:Expr = null;
				ModuleAgency.runThrow(function() {
					e = parser.parseString(code, origin, rp);
				}, function(idk) {
					errored = true;
				}, origin);
				return e;
			}
		}
		return null;
	}
}