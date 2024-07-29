package macros;

#if macro
import haxe.macro.Type.ClassType;
import Type.ValueType;
import haxe.macro.Expr.Function;
import haxe.macro.Expr;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.FieldKind;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.VarAccess;
import haxe.macro.*;
import Sys;
import haxe.io.Path;

using StringTools;
using haxe.macro.PositionTools;

class HashLinkFixer {
	public static var buildMacroString = '@:build(macros.HashLinkFixer.build())';

	public static var applyOn:Array<String> = [
		"flixel",
		"openfl.display.BlendMode"
	];

	public static var modifiedClasses:Array<String> = [];

	public static function init() {
		#if !display
		#if hl
		for(apply in applyOn) {
			compile(apply);
		}
		#end
		#end
	}

	public static function compile(name:String) {
		#if !display
		Compiler.addGlobalMetadata(name, buildMacroString);
		#end
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var clRef = Context.getLocalClass();
		if (clRef == null) return fields;
		var cl = clRef.get();

		if (cl.name.endsWith("_Impl_") && cl.params.length <= 0 && !cl.meta.has(":multiType") && !cl.name.contains("_HSC")) {
			var metas = cl.meta.get();

			var trimEnum = cl.name.substr(0, cl.name.length - 6);

			var key = cl.module;
			var fkey = cl.module + "." + trimEnum;
			if(key == "lime.system.Locale") return fields; // Error: Unknown identifier : currentLocale, Due to Func
			if(key == "cpp.Function") return fields; // Error: Unknown identifier : nativeGetProcAddress, Due to Func
			if(key == "haxe.ds.Vector") return fields; // Error: haxe.ds._Vector.VectorData<blit.T> has no field blit, Due to Func
			if(key == "haxe.display.Display") return fields; // Error: haxe.display.DisplayItemKind<haxe.display.DisplayLiteral<Dynamic>> has no field Null, Due to Func
			if(key == "cpp.Callable") return fields; // Error: cpp.Function.fromStaticFunction must be called on static function, Due to Func
			if(key == "haxe.display.JsonAnonStatusKind") return fields; // Error: cannot initialize a variable of type 'char *' with an rvalue of type 'const char *', Due to Func
			if(key == "cpp.CharStar") return fields; // Error: cannot initialize a variable of type 'char *' with an rvalue of type 'const char *', Due to Func
			if(cl.module.contains("_")) return fields; // Weird issue, sorry

			var shadowClass = macro class {

			};
			shadowClass.kind = TDClass();
			shadowClass.params = switch(cl.params.length) {
				case 0:
					null;
				case 1:
					[{
						name: "T",
					}];
				default:
					[for(k=>e in cl.params) {
						name: "T" + Std.int(k+1)
					}];
			};
			shadowClass.name = '${cl.name.substr(0, cl.name.length - 6)}_HSC';

			var imports = Context.getLocalImports().copy();
			Utils.setupMetas(shadowClass, imports);
			//trace(cl.module);

			for(f in fields)
				switch(f.kind) {
					case FFun(fun):
						if (f.access.contains(AStatic)) {
							if (fun.expr != null) {
								fun.expr = macro @:privateAccess $e{fun.expr};
								shadowClass.fields.push(f);
							}
						}
					case FProp(get, set, t, e):
						if (get == "default" && (set == "never" || set == "null")) {
							shadowClass.fields.push(f);
						}
					case FVar(t, e):
						if (f.access.contains(AStatic) || cl.meta.has(":enum") || f.name.toUpperCase() == f.name) {
							var name:String = f.name;
							var enumType:String = cl.name;
							var pack = cl.module.split(".");

							//trace(pack, cl.name, name, cl.module);

							if(pack[pack.length - 1] == trimEnum)
								pack.pop();

							var complexType:ComplexType = t;
							if(complexType == null && e != null) {
								complexType = switch(e.expr) {
									case EConst(CRegexp(_)): TPath({ name: "EReg", pack: [] });

									default: null;
								}
							}
							if(complexType == null) {
								complexType = TPath({
									name: trimEnum,
									pack: [],//pack
								});
							}

							var code = Context.parse('@:privateAccess ($trimEnum.$name)', f.pos); // '${pack.join(".")}.${trimEnum}.$name'

							var field:Field = {
								pos: f.pos,
								name: f.name,
								meta: f.meta,
								kind: FVar(null, code),
								doc: f.doc,
								access: [APublic, AStatic]
							}

							shadowClass.fields.push(field);
						}
					default:
				}
			Context.defineModule(cl.module, [shadowClass], imports);
		}

		return fields;
	}
}
#else
class HashLinkFixer {
}
#end