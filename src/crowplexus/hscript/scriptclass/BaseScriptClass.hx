package crowplexus.hscript.scriptclass;

class BaseScriptClass {
	public function sc_get(name: String): Dynamic {
		return null;
	}

	public function sc_set(name: String, value: Dynamic): Void {}

	public function sc_call(name: String, ?args: Array<Dynamic>): Dynamic {
		return null;
	}

	public function sc_exists(name: String): Bool {
		return false;
	}
}
