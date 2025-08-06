package crowplexus.hscript.scriptenum;

class ScriptEnumValue {
	public var enumName: String;
	public var name: String;
	public var index: Int;
	public var args: Array<Dynamic>;

	var parent: ScriptEnum;

	public function new(parent: ScriptEnum, enumName: String, name: String, index: Int, ?args: Array<Dynamic>) {
		this.parent = parent;
		this.enumName = enumName;
		this.name = name;
		this.index = index;
		this.args = args;
	}

	public function getEnum(): Dynamic {
		return parent;
	}

	public function toString(): String {
		if (args == null)
			return enumName + "." + name;
		return enumName + "." + name + "(" + [for (arg in args) arg].join(", ") + ")";
	}

	public inline function getEnumName(): String
		return this.enumName;

	public inline function getConstructorArgs(): Array<Dynamic>
		return this.args != null ? this.args : [];

	public function compare(other: ScriptEnumValue): Bool {
		if (enumName != other.enumName || name != other.name)
			return false;
		if (args == null && other.args == null)
			return true;
		if (args == null || other.args == null)
			return false;
		if (args.length != other.args.length)
			return false;

		for (i in 0...args.length) {
			// TODO: allow deep comparison, like arrays
			if (args[i] != other.args[i])
				return false;
		}

		return true;
	}
}
