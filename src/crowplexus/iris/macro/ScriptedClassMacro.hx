package crowplexus.iris.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Printer;
import Type as OType;

/**
 * @see `懒得说`
 * 其实也没借鉴多少hah
 */
class ScriptedClassMacro {
	public static inline var SUPER_FUNCTION_PREFIX:String = "__SC_SUPER_";

	public static function build():Array<Field> {
		var cls:ClassType = Context.getLocalClass().get();
		if(cls.superClass == null) throw "The specified class requires super class.";
		var fields = [];
		fields = fields.concat(buildIDKField());
		var consss = getConstructor(cls);
		if(consss == null) throw "No constructor defined in super class.";
		fields.push(buildConstructor(consss));
		var oversss = getOverrides(cls);
		fields = fields.concat(buildOverrides(oversss));
		fields = fields.concat(buildSuperFunctions(oversss));
		return fields;
	}

	private static function buildIDKField():Array<Field> {
		var fields:Array<Field> = [];
		var f___e_standClass:Field = {
			name: "__sc_standClass",
			access: [APrivate],
			kind: FVar(toComplexType(Context.getType('crowplexus.hscript.scriptclass.ScriptClassInstance'))),
			pos: Context.currentPos(),
		}
		fields.push(f___e_standClass);
		return fields;
	}

	private static function buildConstructor(con:ChouxiangFunction):Field {
		var fnargs = [for(arg in con.args) macro $i{arg.name}];
		var eargs:Array<FunctionArg> = [{
			name: "__sc_standClass",
			type: toComplexType(Context.getType('crowplexus.hscript.scriptclass.ScriptClassInstance'))
		}];
		var field:Field = {
			name: con.name,
			kind: FFun({
				args: eargs.concat([for(arg in con.args) {type: arg.ret, name: arg.name, value: arg.value}]),
				expr: macro {
					this.__sc_standClass = __sc_standClass;
					this.__sc_standClass.superClass = this;
					super($a{fnargs});
				},
				params: con.typeParams
			}),
			pos: Context.currentPos()
		};
		return field;
	}

	private static function getConstructor(cls:ClassType):ChouxiangFunction {
		var superCls:ClassType = cls.superClass?.t.get();
		var func:ChouxiangFunction = null;
		while(superCls != null) {
			if(superCls.constructor != null) {
				final field = superCls.constructor.get();
				var tps:Array<TypeParamDecl> = [];
				if(field.params.length > 0) {
					final params = field.params;
					for(param in params) {
						var tp:TypeParamDecl = convertTypeParam(param);
						tps.push(tp);
					}
				}
				var myFunc = {
					name: field.name,
					args: [],
					typeParams: tps,
					ret: null,
					doThisReturn: false
				};
				switch(field.kind) {
					case FMethod(pd) if(Type.enumEq(pd, MethNormal)):
					case _:
						break;
				}
				var expr = field.expr();
				if(expr != null) {
					switch(expr.expr) {
						case TFunction(pd):
							for(arg in pd.args) {
								var newArg = {
									name: arg.v.name,
									value: arg.value == null ? null : Context.getTypedExpr(arg.value),
									ret: toComplexType(arg.v.t)
								};
								myFunc.args.push(newArg);
							}
						case _:
							break;
					}
				}
				func = myFunc;
				break;
			} else break;
			superCls = cls.superClass?.t.get();
		}
		return func;
	}

	static function buildSuperFunctions(funcs:Array<ChouxiangFunction>):Array<Field> {
		var fields:Array<Field> = [];
		for(fn in funcs) {
			var fname = fn.name;
			var fnargs = [for(arg in fn.args) macro $i{arg.name}];
			fields.push({
				name: SUPER_FUNCTION_PREFIX + fn.name,
				meta: [{name: ":untyped", pos: Context.currentPos()}],
				kind: FFun({
					args: [for(arg in fn.args) {type: arg.ret, name: arg.name, value: arg.value}],
					params: fn.typeParams,
					expr: if(fn.doThisReturn) {
						macro return super.$fname($a{fnargs});
					} else {
						macro super.$fname($a{fnargs});
					}
				}),
				pos: Context.currentPos()
			});
		}
		return fields;
	}

	static function buildOverrides(funcs:Array<ChouxiangFunction>):Array<Field> {
		var fields:Array<Field> = [];
		for(fn in funcs) {
			var fname = fn.name;
			var fnargs = [for(arg in fn.args) macro $i{arg.name}];
			fields.push({
				name: fname,
				access: [AOverride],
				meta: [{name: ":untyped", pos: Context.currentPos()}],
				kind: FFun({
					args: [for(arg in fn.args) {type: arg.ret, name: arg.name, value: arg.value}],
					params: fn.typeParams,
					expr: if(fn.doThisReturn) {
						macro {
							@:privateAccess
							if(__sc_standClass != null && __sc_standClass.overrides.contains(${{expr: EConst(CString(fname)), pos: Context.currentPos()}})) {
								var result = __sc_standClass.sc_call(${{expr: EConst(CString(fname)), pos: Context.currentPos()}}, [$a{fnargs}]);
								return cast result;
							}
							else return super.$fname($a{fnargs});
						}
					} else {
						macro {
							@:privateAccess
							if(__sc_standClass != null && __sc_standClass.overrides.contains(${{expr: EConst(CString(fname)), pos: Context.currentPos()}})) {
								var result = __sc_standClass.sc_call(${{expr: EConst(CString(fname)), pos: Context.currentPos()}}, [$a{fnargs}]);
							}
							else super.$fname($a{fnargs});
						}
					}
				}),
				pos: Context.currentPos()
			});
		}
		return fields;
	}

	static function convertTypeParam(tpr:TypeParameter):TypeParamDecl {
		function parse(t:Type, tp:TypeParamDecl) {
			switch(t) {
				case TInst(ctrl, grp):
					if(grp.length > 0) {
						if(!Reflect.hasField(tp, "params")) Reflect.setField(tp, "params", []);
						for(b in grp) {
							var newTp:TypeParamDecl = {name: tpr.name};
							parse(b, newTp);
							tp.params.push(newTp);
						}
					}
					switch(ctrl.get().kind) {
						case KTypeParameter(csgo):
							if(csgo.length > 0) {
								for(c in csgo) {
									if(!Reflect.hasField(tp, "constraints")) Reflect.setField(tp, "constraints", []);
									tp.constraints.push(toComplexType(c));
								}
							}
						case _:
					}
				case _:
			}
		}

		var tp:TypeParamDecl = {name: tpr.name};
		parse(tpr.t, tp);
		return tp;
	}

	private static function getOverrides(cls:ClassType):Array<ChouxiangFunction> {
		var funcs:Array<ChouxiangFunction> = [];
		var superCls:ClassType = cls.superClass?.t.get();
		//var tpss:Array<TypeParamDecl> = getSuperclassParams(cls);
		//var pause:Bool = false;

		while(superCls != null) {
			//if(!pause && superCls != null && superCls.params.length > 0) {
			//	pause = true;
			//	for(param in superCls.params) {
			//		var tp:TypeParamDecl = convertTypeParam(param);
			//		tpss.push(tp);
			//	}
			//}
			for(f in superCls.fields.get()) {
				if(Lambda.find(funcs, (field) -> field.name == f.name) != null) {
					continue;
				}
				var tps:Array<TypeParamDecl> = [];
				if(f.params.length > 0) {
					final params = f.params;
					for(param in params) {
						var tp:TypeParamDecl = convertTypeParam(param);
						tps.push(tp);
					}
				}
				switch(f.kind) {
					case FMethod(mk) if(Type.enumEq(mk, MethNormal)):
						if(Lambda.find(funcs, (fun) -> fun.name == f.name) == null) {
							var func = {
								name: f.name,
								args: [],
								typeParams: tps,
								ret: toComplexType(f.type),
								doThisReturn: true
							};
							var expr = f.expr();
							if(expr != null) {
								switch(expr.expr) {
									case TFunction(fd):
										func.ret = toComplexType(fd.t);
										switch(fd.t) {
											case TAbstract(sb, _) if(sb.toString() == "Void"):
												func.doThisReturn = false;
											case _:
										}
										for(arg in fd.args) {
											var newArg = {
												name: arg.v.name,
												value: arg.value == null ? null : Context.getTypedExpr(arg.value),
												ret: toComplexType(arg.v.t)
											};
											func.args.push(newArg);
										}
									case _:
								}
							}
							funcs.push(func);
						}
					case _:
				}
			}
			superCls = superCls.superClass?.t.get();
		}
		return funcs;
	}

	private static function toComplexType(t:Type):ComplexType {
		switch(t) {
			case TAbstract(ctrl, grp):
				final cp = ctrl.get();
				var np:TypePath = {
					pack: cp.pack,
					name: cp.module.substring(cp.module.lastIndexOf(".") + 1),
					sub: cp.name,
					params: [for(g in grp) toTypeParam(g)]
				};
				return TPath(np);
			case TInst(ctrl, grp):
				switch(ctrl.get().kind) {
					case KTypeParameter(idks):
						for(idk in idks) {
							return toComplexType(idk);
						}
						return toComplexType(TDynamic(null));
					case _:
				}
			case TFun(args, ret):
				var newArgs:Array<ComplexType> = [];
				var newRet:ComplexType = toComplexType(ret);
				for(arg in args) {
					newArgs.push((arg.opt ? TOptional(toComplexType(arg.t)) : toComplexType(arg.t)));
				}
				return TFunction(newArgs, newRet);
			default:
		}
		return Context.toComplexType(t);
	}

	static function toTypeParam(type:Type):TypeParam
		return {
			switch (type) {
				case TInst(_.get() => {kind: KExpr(e)}, _): TPExpr(e);
				case _: TPType(toComplexType(type));
			}
		}
}

typedef ChouxiangFunction = {
	var name:String;
	var args:Array<ChouxiangArg>;
	var typeParams:Array<TypeParamDecl>;
	var ret:ComplexType;
	var doThisReturn:Bool;
}

typedef ChouxiangArg = {
	var name:String;
	var value:Null<Expr>;
	var ret:ComplexType;
}