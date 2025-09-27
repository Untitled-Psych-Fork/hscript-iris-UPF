package crowplexus.hscript.scriptclass;

class BaseScriptClass {
	public function sc_get(name: String, isScript:Bool = false, inClass:Bool = false): Dynamic {
		return null;
	}

	public function sc_set(name: String, value: Dynamic): Void {}

	public function sc_call(name: String, ?args: Array<Dynamic>): Dynamic {
		return null;
	}

	public function sc_exists(name: String): Bool {
		return false;
	}

	public function getFields(): Array<String> {
		return [];
	}

	public function getFieldsWithOverride(): Array<String> {
		return [];
	}

	public function getStaticFields(): Array<String> {
		return [];
	}

	public function getVars(): Array<String> {
		return [];
	}

	public function getFunctions(): Array<String> {
		return [];
	}
}
