/*
 * Copyright (C)2008-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package crowplexus.hscript;

import Type.ValueType;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;
import crowplexus.iris.Iris;
import crowplexus.iris.IrisUsingClass;
import crowplexus.iris.utils.UsingEntry;
import haxe.Constraints.IMap;
import haxe.PosInfos;

private enum Stop {
	SBreak;
	SContinue;
	SReturn;
}

@:structInit
class LocalVar {
	public var r: Dynamic;
	public var const: Bool;
}

@:structInit
class DeclaredVar {
	public var n: String;
	public var old: LocalVar;
}

@:allow(crowplexus.hscript.PropertyAccessor)
class Interp {
	public static var staticVariables: #if haxe3 Map<String, Dynamic> = new Map() #else Hash<Dynamic> = new Hash() #end;

	public var scriptObject(default, set): Dynamic;
	public var parentInstance(default, set): Dynamic;
	
	#if haxe3
	public var variables: Map<String, Dynamic>;
	public var imports: Map<String, Dynamic>;
	public var props: Map<String, Dynamic>;
	var locals: Map<String, LocalVar>;
	var binops: Map<String, Expr->Expr->Dynamic>;
	var propertyLinks: Map<String, PropertyAccessor>;
	#else
	public var variables: Hash<Dynamic>;
	public var imports: Hash<Dynamic>;
	public var props: Hash<Dynamic>;
	var locals: Hash<LocalVar>;
	var binops: Hash<Expr->Expr->Dynamic>;
	var propertyLinks: Hash<PropertyAccessor>;
	#end

	var _parentFields: Array<String> = [];
	var __instanceFields: Array<String> = [];
	var depth: Int;
	var inTry: Bool;
	var declared: Array<DeclaredVar>;
	var returnValue: Dynamic;

	@:noCompletion static var unpackClassCache: #if haxe3 Map<String, Dynamic> = new Map() #else Hash<Dynamic> = new Hash() #end;
	public static var getRedirects: Map<String, Dynamic->String->Dynamic> = [];
	public static var setRedirects: Map<String, Dynamic->String->Dynamic->Dynamic> = [];

	#if hscriptPos
	var curExpr: Expr;
	#end

	public var showPosOnLog: Bool = true;

	function set_scriptObject(v: Dynamic) {
		__instanceFields = Type.getInstanceFields(Type.getClass(v));
		return scriptObject = v;
	}

	function set_parentInstance(val: Dynamic): Dynamic {
		if (val != null) {
			switch (Type.typeof(val)) {
				case Type.ValueType.TObject if (!(val is Enum)):
					_parentFields = if (val is Class) Type.getClassFields(val) else Reflect.fields(val);
				case Type.ValueType.TClass(_):
					_parentFields = Type.getInstanceFields(Type.getClass(val));
				case _:
			}
		}
		if (_parentFields == null) _parentFields = [];
		return parentInstance = val;
	}

	public function new() {
		#if haxe3
		locals = new Map();
		variables = new Map<String, Dynamic>();
		props = new Map<String, Dynamic>();
		imports = new Map<String, Dynamic>();
		binops = new Map();
		propertyLinks = new Map();
		#else
		locals = new Hash();
		variables = new Hash();
		props = new Hash();
		imports = new Hash();
		binops = new Hash();
		propertyLinks = new Hash();
		#end
		declared = new Array();
		resetVariables();
		initOps();
	}

	private function resetVariables() {
		variables.set("null", null);
		variables.set("true", true);
		variables.set("false", false);
		variables.set("trace", Reflect.makeVarArgs(function(el) {
			var inf = posInfos();
			var v = el.shift();
			if (el.length > 0)
				inf.customParams = el;
			haxe.Log.trace(Std.string(v), inf);
		}));
	}

	public function posInfos(): PosInfos {
		#if hscriptPos
		if (curExpr != null)
			return cast {fileName: curExpr.origin, lineNumber: curExpr.line};
		#end
		return cast {fileName: "hscript", lineNumber: 0};
	}

	function initOps() {
		var me = this;
		binops.set("+", function(e1, e2) return me.expr(e1) + me.expr(e2));
		binops.set("-", function(e1, e2) return me.expr(e1) - me.expr(e2));
		binops.set("*", function(e1, e2) return me.expr(e1) * me.expr(e2));
		binops.set("/", function(e1, e2) return me.expr(e1) / me.expr(e2));
		binops.set("%", function(e1, e2) return me.expr(e1) % me.expr(e2));
		binops.set("&", function(e1, e2) return me.expr(e1) & me.expr(e2));
		binops.set("|", function(e1, e2) return me.expr(e1) | me.expr(e2));
		binops.set("^", function(e1, e2) return me.expr(e1) ^ me.expr(e2));
		binops.set("<<", function(e1, e2) return me.expr(e1) << me.expr(e2));
		binops.set(">>", function(e1, e2) return me.expr(e1) >> me.expr(e2));
		binops.set(">>>", function(e1, e2) return me.expr(e1) >>> me.expr(e2));
		binops.set("==", function(e1, e2) return me.expr(e1) == me.expr(e2));
		binops.set("!=", function(e1, e2) return me.expr(e1) != me.expr(e2));
		binops.set(">=", function(e1, e2) return me.expr(e1) >= me.expr(e2));
		binops.set红包: 2/3/2023 18:43:54
		binops.set("<=", function(e1, e2) return me.expr(e1) <= me.expr(e2));
		binops.set(">", function(e1, e2) return me.expr(e1) > me.expr(e2));
		binops.set("<", function(e1, e2) return me.expr(e1) < me.expr(e2));
		binops.set("||", function(e1, e2) return me.expr(e1) == true || me.expr(e2) == true);
		binops.set("&&", function(e1, e2) return me.expr(e1) == true && me.expr(e2) == true);
		binops.set("=", assign);
		binops.set("??", function(e1, e2) {
			var expr1: Dynamic = me.expr(e1);
			return expr1 == null ? me.expr(e2) : expr1;
		});
		binops.set("...", function(e1, e2) return new InterpIterator(me, e1, e2));
		assignOp("+=", function(v1: Dynamic, v2: Dynamic) return v1 + v2);
		assignOp("-=", function(v1: Float, v2: Float) return v1 - v2);
		assignOp("*=", function(v1: Float, v2: Float) return v1 * v2);
		assignOp("/=", function(v1: Float, v2: Float) return v1 / v2);
		assignOp("%=", function(v1: Float, v2: Float) return v1 % v2);
		assignOp("&=", function(v1, v2) return v1 & v2);
		assignOp("|=", function(v1, v2) return v1 | v2);
		assignOp("^=", function(v1, v2) return v1 ^ v2);
		assignOp("<<=", function(v1, v2) return v1 << v2);
		assignOp(">>=", function(v1, v2) return v1 >> v2);
		assignOp(">>>=", function(v1, v2) return v1 >>> v2);
		assignOp("??=", function(v1, v2) return v1 == null ? v2 : v1);
	}

	public inline function setVar(name: String, v: Dynamic) {
		if (propertyLinks.exists(name)) {
			var l = propertyLinks.get(name);
			if (l.inState)
				l.set(name, v);
			else
				l.link_setFunc(v);
			return;
		}

		if (staticVariables.exists(name)) {
			staticVariables.set(name, v);
		} else if (staticVariables.exists('$name;const')) {
			warn(ECustom("Cannot reassign final, for constant expression -> " + name));
		} else if (parentInstance != null && (_parentFields.contains(name) || _parentFields.contains('set_$name'))) {
			Reflect.setProperty(parentInstance, name, v);
		} else if (scriptObject != null) {
			if (Type.typeof(scriptObject) == TObject) {
				Reflect.setField(scriptObject, name, v);
			} else if (__instanceFields.contains(name)) {
				Reflect.setProperty(scriptObject, name, v);
			} else if (__instanceFields.contains('set_$name')) {
				Reflect.getProperty(scriptObject, 'set_$name')(v);
			} else {
				variables.set(name, v);
			}
		} else {
			variables.set(name, v);
		}
	}

	function assign(e1: Expr, e2: Expr): Dynamic {
		var v = expr(e2);
		switch (Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				if (l == null)
					setVar(id, v);
				else {
					if (l.const != true)
						l.r = v;
					else
						warn(ECustom("Cannot reassign final, for constant expression -> " + id));
				}
			case EField(e, f, s):
				var e = expr(e);
				if (e == null)
					if (!s)
						error(EInvalidAccess(f));
					else
						return null;
				v = set(e, f, v);
			case EArray(e, index):
				var arr: Dynamic = expr(e);
				var index: Dynamic = expr(index);
				if (isMap(arr)) {
					setMapValue(arr, index, v);
				} else {
					arr[index] = v;
				}
			default:
				error(EInvalidOp("="));
		}
		return v;
	}

	function assignOp(op, fop: Dynamic->Dynamic->Dynamic) {
		var me = this;
		binops.set(op, function(e1, e2) return me.evalAssignOp(op, fop, e1, e2));
	}

	function evalAssignOp(op, fop, e1, e2): Dynamic {
		var v;
		switch (Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l == null) {
					if (parentInstance != null && (_parentFields.contains(id) || _parentFields.contains('set_$id'))) {
						Reflect.setProperty(parentInstance, id, v);
					} else if (scriptObject != null && (__instanceFields.contains(id) || __instanceFields.contains('set_$id'))) {
						Reflect.setProperty(scriptObject, id, v);
					} else {
						setVar(id, v);
					}
				} else {
					if (l.const != true)
						l.r = v;
					else
						warn(ECustom("Cannot reassign final, for constant expression -> " + id));
				}
			case EField(e, f, s):
				var obj = expr(e);
				if (obj == null)
					if (!s)
						error(EInvalidAccess(f));
					else
						return null;
				v = fop(get(obj, f), expr(e2));
				v = set(obj, f, v);
			case EArray(e, index):
				var arr: Dynamic = expr(e);
				var index: Dynamic = expr(index);
				if (isMap(arr)) {
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				} else {
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}

	function increment(e: Expr, prefix: Bool, delta: Int): Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch (e) {
			case EIdent(id):
				var l = locals.get(id);
				var v: Dynamic = (l == null) ? resolve(id) : l.r;
				function setTo(a) {
					if (l == null)
						setVar(id, a);
					else {
						if (l.const != true)
							l.r = a;
						else
							error(ECustom("Cannot reassign final, for constant expression -> " + id));
					}
				}
				if (prefix) {
					v += delta;
					setTo(v);
				} else
					setTo(v + delta);
				return v;
			case EField(e, f, s):
				var obj = expr(e);
				if (obj == null)
					if (!s)
						error(EInvalidAccess(f));
					else
						return null;
				var v: Dynamic = get(obj, f);
				if (prefix) {
					v += delta;
					set(obj, f, v);
				} else
					set(obj, f, v + delta);
				return v;
			case EArray(e, index):
				var arr: Dynamic = expr(e);
				var index: Dynamic = expr(index);
				if (isMap(arr)) {
					var v = getMapValue(arr, index);
					if (prefix) {
						v += delta;
						setMapValue(arr, index, v);
					} else {
						setMapValue(arr, index, v + delta);
					}
					return v;
				} else {
					var v = arr[index];
					if (prefix) {
						v += delta;
						arr[index] = v;
					} else
						arr[index] = v + delta;
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0) ? "++" : "--"));
		}
	}

	public function execute(expr: Expr): Dynamic {
		depth = 0;
		#if haxe3
		locals = new Map();
		#else
		locals = new Hash();
		#end
		declared = new Array();
		return exprReturn(expr);
	}

	function exprReturn(e): Dynamic {
		try {
			return expr(e);
		} catch (e: Stop) {
			switch (e) {
				case SBreak:
					throw "Invalid break";
				case SContinue:
					throw "Invalid continue";
				case SReturn:
					var v = returnValue;
					returnValue = null;
					return v;
			}
		}
		return null;
	}

	function duplicate<T>(h: #if haxe3 Map<String, T> #else Hash<T> #end) {
		#if haxe3
		var h2 = new Map();
		#else
		var h2 = new Hash();
		#end
		for (k in h.keys())
			h2.set(k, h.get(k));
		return h2;
	}

	function restore(old: Int) {
		while (declared.length > old) {
			var d = declared.pop();
			locals.set(d.n, d.old);
		}
	}

	inline function error(e: #if hscriptPos ErrorDef #else Error #end, rethrow = false): Dynamic {
		#if hscriptPos var e = new Error(e, curExpr.pmin, curExpr.pmax, curExpr.origin, curExpr.line); #end
		if (rethrow)
			this.rethrow(e)
		else
			throw e;
		return null;
	}

	inline function warn(e: #if hscriptPos ErrorDef #else Error #end): Dynamic {
		#if hscriptPos var e = new Error(e, curExpr.pmin, curExpr.pmax, curExpr.origin, curExpr.line); #end
		Iris.warn(Printer.errorToString(e, showPosOnLog), #if hscriptPos posInfos() #else null #end);
		return null;
	}

	inline function rethrow(e: Dynamic) {
		#if hl
		hl.Api.rethrow(e);
		#else
		throw e;
		#end
	}

	function resolve(id: String): Dynamic {
		var l = locals.get(id);
		if (l != null) return l.r;

		if (propertyLinks.exists(id)) {
			var l = propertyLinks.get(id);
			if (l.inState)
				return l.get(id);
			else
				return l.link_getFunc();
		}

		if (staticVariables.exists(id))
			return staticVariables.get(id);
		else if (staticVariables.exists('$id;const'))
			return staticVariables.get('$id;const');

		if (variables.exists(id))
			return variables.get(id);

		if (parentInstance != null) {
			if (id == "this")
				return parentInstance;
			if (_parentFields.contains(id) || _parentFields.contains('get_$id'))
				return Reflect.getProperty(parentInstance, id);
		}

		if (scriptObject != null) {
			if (id == "this")
				return scriptObject;
			if (Type.typeof(scriptObject) == TObject && Reflect.hasField(scriptObject, id))
				return Reflect.field(scriptObject, id);
			if (__instanceFields.contains(id))
				return Reflect.getProperty(scriptObject, id);
			if (__instanceFields.contains('get_$id'))
				return Reflect.getProperty(scriptObject, 'get_$id')();
		}

		if (imports.exists(id))
			return imports.get(id);

		if (unpackClassCache.exists(id))
			return unpackClassCache.get(id);
		
		var cl = Type.resolveClass(id);
		if (cl != null) {
			unpackClassCache.set(id, cl);
			return cl;
		}

		error(EUnknownVariable(id));
		return null;
	}

	public function getOrImportClass(name: String): Dynamic {
		if (Iris.proxyImports.exists(name))
			return Iris.proxyImports.get(name);
		return Tools.getClass(name);
	}

	public function expr(e: Expr): Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch (e) {
			case EIgnore(_):
			case EConst(c):
				return switch (c) {
					case CInt(v): v;
					case CFloat(f): f;
					case CString(s): s;
					#if !haxe3
					case CInt32(v): v;
					#end
				}
			case EIdent(id):
				return resolve(id);
			case EVar(n, _, v, getter, setter, isConst, s):
				if (getter == null) getter = "default";
				if (setter == null) setter = "default";
				var v = (v == null ? null : expr(v));
				if (s == true) {
					if (!staticVariables.exists(n) && !staticVariables.exists(n + ";const")) {
						if (isConst)
							staticVariables.set(n + ";const", v);
						else {
							staticVariables.set(n, v);
							if (getter != "default" || setter != "default") {
								propertyLinks.set(n, new PropertyAccessor(this, () -> {
									if (staticVariables.exists(n))
										return staticVariables.get(n);
									else
										throw error(EUnknownVariable(n));
									return null;
								}, (val) -> {
									if (staticVariables.exists(n))
										staticVariables.set(n, val);
									else
										throw error(EUnknownVariable(n));
									return val;
								}, getter, setter, true));
							}
						}
					}
				} else {
					if (!isConst && (getter != "default" || setter != "default")) {
						props.set(n, v);
						propertyLinks.set(n, new PropertyAccessor(this, () -> {
							if (props.exists(n))
								return props.get(n);
							else
								throw error(EUnknownVariable(n));
							return null;
						}, (val) -> {
							if (props.exists(n))
								props.set(n, val);
							else
								throw error(EUnknownVariable(n));
							return val;
						}, getter, setter));
					} else {
						declared.push({n: n, old: locals.get(n)});
						locals.set(n, {r: v, const: isConst});
					}
				}
				return null;
			case EParent(e):
				return expr(e);
			case EBlock(exprs):
				var old = declared.length;
				var v = null;
				for (e in exprs)
					v = expr(e);
				restore(old);
				return v;
			case EField(e, f, true):
				var e = expr(e);
				if (e == null)
					return null;
				return get(e, f);
			case EField(e, f, false):
				return get(expr(e), f);
			case EBinop(op, e1, e2):
				var fop = binops.get(op);
				if (fop == null)
					error(EInvalidOp(op));
				return fop(e1, e2);
			case EUnop(op, prefix, e):
				return switch (op) {
					case "!": expr(e) != true;
					case "-": -expr(e);
					case "++": increment(e, prefix, 1);
					case "--": increment(e, prefix, -1);
					case "~":
						#if (neko && !haxe3)
						haxe.Int32.complement(expr(e));
						#else
						~expr(e);
						#end
					default: error(EInvalidOp(op)); null;
				}
			case ECall(e, params):
				var args = new Array();
				for (p in params)
					args.push(expr(p));
				switch (Tools.expr(e)) {
					case EField(e, f, s):
						var obj = expr(e);
						if (obj == null)
							if (!s)
								error(EInvalidAccess(f));
						return fcall(obj, f, args);
					default:
						return call(null, expr(e), args);
				}
			case EIf(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else if (e2 == null) null else expr(e2);
			case EWhile(econd, e):
				whileLoop(econd, e);
				return null;
			case EDoWhile(econd, e):
				doWhileLoop(econd, e);
				return null;
			case EFor(v, it, e):
				forLoop(v, it, e);
				return null;
			case EBreak:
				throw SBreak;
			case EContinue:
				throw SContinue;
			case EReturn(e):
				returnValue = e == null ? null : expr(e);
				throw SReturn;
			case EImport(v, as):
				final aliasStr = (as != null ? " named " + as : "");
				if (Iris.blocklistImports.contains(v)) {
					error(ECustom("You cannot add a blacklisted import, for class " + v + aliasStr));
					return null;
				}
				var n = Tools.last(v.split("."));
				if (imports.exists(n))
					return imports.get(n);
				var c: Dynamic = getOrImportClass(v);
				if (c == null)
					return warn(ECustom("Import" + aliasStr + " of class " + v + " could not be added"));
				else {
					imports.set(n, c);
					if (as != null)
						imports.set(as, c);
				}
				return null;
			case EFunction(params, fexpr, name, _, s):
				var capturedLocals = duplicate(locals);
				var me = this;
				var hasOpt = false, minParams = 0;
				for (p in params)
					if (p.opt)
						hasOpt = true;
					else
						minParams++;
				var f = function(args: Array<Dynamic>) {
					if (((args == null) ? 0 : args.length) != params.length) {
						if (args.length < minParams) {
							var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
							if (name != null)
								str += " for function '" + name + "'";
							error(ECustom(str));
						}
						var args2 = [];
						var extraParams = args.length - minParams;
						var pos = 0;
						for (p in params)
							if (p.opt) {
								if (extraParams > 0) {
									args2.push(args[pos++]);
									extraParams--;
								} else
									args2.push(null);
							} else
								args2.push(args[pos++]);
						args = args2;
					}
					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					for (i in 0...params.length)
						me.locals.set(params[i].name, {r: args[i], const: false});
					var r = null;
					var oldDecl = declared.length;
					if (inTry)
						try {
							r = me.exprReturn(fexpr);
						} catch (e: Dynamic) {
							me.locals = old;
							me.depth = depth;
							#if neko
							neko.Lib.rethrow(e);
							#else
							throw e;
							#end
						}
					else
						r = me.exprReturn(fexpr);
					restore(oldDecl);
					me.locals = old;
					me.depth = depth;
					return r;
				};
				var f = Reflect.makeVarArgs(f);
				if (name != null) {
					if (depth == 0) {
						if (s == true) {
							if (!staticVariables.exists(name))
								staticVariables.set(name, f);
						} else
							variables.set(name, f);
					} else {
						declared.push({n: name, old: locals.get(name)});
						var ref: LocalVar = {r: f, const: false};
						locals.set(name, ref);
						capturedLocals.set(name, ref);
					}
				}
				return f;
			case EArrayDecl(arr):
				if (arr.length > 0 && Tools.expr(arr[0]).match(EBinop("=>", _))) {
					var isAllString: Bool = true;
					var isAllInt: Bool = true;
					var isAllObject: Bool = true;
					var isAllEnum: Bool = true;
					var keys: Array<Dynamic> = [];
					var values: Array<Dynamic> = [];
					for (e in arr) {
						switch (Tools.expr(e)) {
							case EBinop("=>", eKey, eValue): {
								var key: Dynamic = expr(eKey);
								var value: Dynamic = expr(eValue);
								isAllString = isAllString && (key is String);
								isAllInt = isAllInt && (key is Int);
								isAllObject = isAllObject && Reflect.isObject(key);
								isAllEnum = isAllEnum && Reflect.isEnumValue(key);
								keys.push(key);
								values.push(value);
							}
							default: throw("=> expected");
						}
					}
					var map: Dynamic = {
						if (isAllInt)
							new haxe.ds.IntMap<Dynamic>();
						else if (isAllString)
							new haxe.ds.StringMap<Dynamic>();
						else if (isAllEnum)
							new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
						else if (isAllObject)
							new haxe.ds.ObjectMap<Dynamic, Dynamic>();
						else
							throw 'Inconsistent key types';
					}
					for (n in 0...keys.length) {
						setMapValue(map, keys[n], values[n]);
					}
					return map;
				} else {
					var a = new Array();
					for (e in arr) {
						a.push(expr(e));
					}
					return a;
				}
			case EArray(e, index):
				var arr: Dynamic = expr(e);
				var index: Dynamic = expr(index);
				if (isMap(arr)) {
					return getMapValue(arr, index);
				} else {
					return arr[index];
				}
			case ENew(cl, params):
				var a = new Array();
				for (e in params)
					a.push(expr(e));
				return cnew(cl, a);
			case EThrow(e):
				throw expr(e);
			case ETry(e, n, _, ecatch):
				var old = declared.length;
				var oldTry = inTry;
				try {
					inTry = true;
					var v: Dynamic = expr(e);
					restore(old);
					inTry = oldTry;
					return v;
				} catch (err: Stop) {
					inTry = oldTry;
					throw err;
				} catch (err: Dynamic) {
					restore(old);
					inTry = oldTry;
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: err, const: false});
					var v: Dynamic = expr(ecatch);
					restore(old);
					return v;
				}
			case EObject(fl):
				var o = {};
				for (f in fl)
					set(o, f.name, expr(f.e));
				return o;
			case ETernary(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else expr(e2);
			case ESwitch(e, cases, def):
				var val: Dynamic = expr(e);
				var match = false;
				for (c in cases) {
					for (v in c.values)
						if ((!Type.enumEq(Tools.expr(v), EIdent("_")) && expr(v) == val) && (c.ifExpr == null || expr(c.ifExpr) == true)) {
							match = true;
							break;
						}
					if (match) {
						val = expr(c.expr);
						break;
					}
				}
				if (!match)
					val = def == null ? null : expr(def);
				return val;
			case EMeta(_, _, e):
				return expr(e);
			case ECheckType(e, _):
				return expr(e);
			case EEnum(enumName, fields):
				var obj = {};
				for (index => field in fields) {
					switch (field) {
						case ESimple(name):
							Reflect.setField(obj, name, new EnumValue(enumName, name, index, null));
						case EConstructor(name, params):
							var hasOpt = false, minParams = 0;
							for (p in params)
								if (p.opt)
									hasOpt = true;
								else
									minParams++;
							var f = function(args: Array<Dynamic>) {
								if (((args == null) ? 0 : args.length) != params.length) {
									if (args.length < minParams) {
										var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
										if (enumName != null)
											str += " for enum '" + enumName + "'";
										error(ECustom(str));
									}
									var args2 = [];
									var extraParams = args.length - minParams;
									var pos = 0;
									for (p in params)
										if (p.opt) {
											if (extraParams > 0) {
												args2.push(args[pos++]);
												extraParams--;
											} else
												args2.push(null);
										} else
											args2.push(args[pos++]);
									args = args2;
								}
								return new EnumValue(enumName, name, index, args);
							};
							var f = Reflect.makeVarArgs(f);
							Reflect.setField(obj, name, f);
					}
				}
				variables.set(enumName, obj);
			case EDirectValue(value):
				return value;
			case EUsing(name):
				useUsing(name);
		}
		return null;
	}

	function doWhileLoop(econd, e) {
		var old = declared.length;
		do {
			try {
				expr(e);
			} catch (err: Stop) {
				switch (err) {
					case SContinue:
					case SBreak:
						break;
					case SReturn:
						throw err;
				}
			}
		} while (expr(econd) == true);
		restore(old);
	}

	function whileLoop(econd, e) {
		var old = declared.length;
		while (expr(econd) == true) {
			try {
				expr(e);
			} catch (err: Stop) {
				switch (err) {
					case SContinue:
					case SBreak:
						break;
					case SReturn:
						throw err;
				}
			}
		}
		restore(old);
	}

	function makeIterator(v: Dynamic): Iterator<Dynamic> {
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.iterator != null)
			v = v.iterator();
		#else
		try
			v = v.iterator()
		catch (e: Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	function forLoop(n, it, e) {
		var old = declared.length;
		declared.push({n: n, old: locals.get(n)});
		var it = makeIterator(expr(it));
		var _itHasNext = it.hasNext;
		var _itNext = it.next;
		while (_itHasNext()) {
			locals.set(n, {r: _itNext(), const: false});
			try {
				expr(e);
			} catch (err: Stop) {
				switch (err) {
					case SContinue:
					case SBreak:
						break;
					case SReturn:
						throw err;
				}
			}
		}
		restore(old);
	}

	inline function isMap(o: Dynamic): Bool {
		return (o is IMap);
	}

	inline function getMapValue(map: Dynamic, key: Dynamic): Dynamic {
		return cast(map, IMap<Dynamic, Dynamic>).get(key);
	}

	inline function setMapValue(map: Dynamic, key: Dynamic, value: Dynamic): Void {
		cast(map, IMap<Dynamic, Dynamic>).set(key, value);
	}

	function get(o: Dynamic, f: String): Dynamic {
		if (o == null)
			error(EInvalidAccess(f));
		var cl: String = switch (Type.typeof(o)) {
			case TNull: "Null";
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case _: null;
		};
		var redirect: Dynamic->String->Dynamic = getRedirects.exists(cl = Type.getClassName(Type.getClass(o))) ? getRedirects[cl] : null;
		if (redirect != null)
			return redirect(o, f);
		#if php
		try {
			return Reflect.getProperty(o, f);
		} catch (e: Dynamic) {
			return Reflect.field(o, f);
		}
		#else
		return Reflect.getProperty(o, f);
		#end
	}

	function set(o: Dynamic, f: String, v: Dynamic): Dynamic {
		if (o == null)
			error(EInvalidAccess(f));
		var cl: String = switch (Type.typeof(o)) {
			case TNull: "Null";
			case TInt: "Int";
			case TFloat: "Float";
			case TBool: "Bool";
			case _: null;
		};
		var redirect: Dynamic->String->Dynamic->Dynamic = setRedirects.exists(cl = Type.getClassName(Type.getClass(o))) ? setRedirects[cl] : null;
		if (redirect != null)
			return redirect(o, f,
