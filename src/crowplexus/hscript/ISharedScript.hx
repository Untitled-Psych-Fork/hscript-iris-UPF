package crowplexus.hscript;

import crowplexus.hscript.Expr;

/**
 * 我摊牌了，直接抄
 */
interface ISharedScript {
	public var standard(get, never):Dynamic;
	public function get_standard():Dynamic;

	public function hget(name: String, ?expr: Expr): Dynamic;
	public function hset(name: String, value: Dynamic, ?expr: Expr): Void;
}
