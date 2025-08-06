package crowplexus.hscript;

import crowplexus.hscript.Expr;

/**
 * 我摊牌了，直接抄
 */
interface ISharedScript {
	public function hget(name: String, ?expr: Expr): Dynamic;
	public function hset(name: String, value: Dynamic, ?expr: Expr): Void;
}
