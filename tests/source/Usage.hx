package;

using StringTools;

class Usage {
	public static function init() {
		Xml.parse("");
		var regex = new EReg("ah", "");
		regex.match("ah");
		regex.matched(0);
		"sb1".endsWith("1");
		trace(Type.getClassFields(StringTools));
	}
}