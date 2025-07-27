package;

import samples.*;
import scripted.*;
import crowplexus.hscript.Interp;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Expr;
import crowplexus.hscript.scriptclass.IScriptedClass;
import crowplexus.iris.Iris;

@:build(macros.TestingMacro.build())
class Main {
	public static function test_hello_world() {
		var script:HScript = new HScript("hello_world");
		script.execute();
		script.call("onCreate");
		for(i in 0...9) script.call("mathTen");
	}

	public static function test_static_variables() {
		var script1:HScript = new HScript("static_variables_1");
		script1.execute();
		var script1:HScript = new HScript("static_variables_2");
		script1.execute();
		script1.call("onCreate");
	}

	@:testName("typedef & name")
	public static function test_typedef_enum() {
		var script:HScript = new HScript("typedef_enum");
		script.execute();
	}

	@:testName("regex & interpolation")
	public static function test_regex_interpolation() {
		var script:HScript = new HScript("test_regex_interpolation", true);
		script.set("interpolation_player", "Beihu235");
		script.execute();
	}

	public static function test_class_samples() {
		var script:HScript = new HScript("class_samples");
		script.execute();
	}

	public static function main() {
		Main.init();
	}

	@:noCompletion static function loadNeeded() {
		trace(ScriptedBaseSample);
		trace(ScriptedGroupSample);
		trace(ObjectSample);
		trace(IntSample);
	}

	static function init() {
		Assets.init(haxe.io.Path.addTrailingSlash(Sys.getCwd()) + "assets", ["hxc", "hxs"]);
	}
}

@:noOverride("loser")
class TestB extends TestA implements IScriptedClass {}

class TestA {
	public function new() {}

	public function loser() {}
}