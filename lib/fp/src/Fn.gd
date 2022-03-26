class_name Fn

static func apply(z: Callable, ctx: Variant):
	return z.call(ctx)

static func find_index(iterable, cb) -> int:
	for v in iterable:
		if cb.call(v):
			return v
	return -1

static func make_signal(obj: Object, name: String) -> Signal:
	obj.add_user_signal(name)
	return Signal(obj, name)


static func _gen_vararg(count: int = 32):
	var arg_string = ""
	var convert_string = ""
	for v in count:
		arg_string += "_%d = Dummy" % v
		if v < count - 1:
			arg_string += ", "
		
		convert_string += """
		if !(_%d is Object && _%d == Dummy):
			ret.append(_%d)
		else:
			var cb = ret.pop_back()
			cb.call(ret)
			return""" % [v,v, v]
	
	var script = GDScript.new()
	script.source_code = """
class Dummy:
	pass

static func make_vararg():
	return func(%s):
		var ret: Array = []
		%s
	""" % [arg_string, convert_string]
	script.reload()
	
	return script

class _Ref:
	pass

static func squash(cb: Callable):
	var sc: Object = _Ref.new().script # "lazy static"
	if !sc.has_meta("gen"):
		sc.set_meta("gen", _gen_vararg())
	var obj = sc.get_meta("gen")
	
	return obj.make_vararg().bind(cb)

static func spread(cb: Callable) -> Callable:
	return func(args: Array):
		args.reverse()
		for arg in args:
			cb = cb.bind(arg)
		return cb.call()

class _Bridge:
	var value

static func connect_with_bail(sig: Signal, cb: Callable) -> void:
	var bridge = _Bridge.new()
	var cb2 = cb.bind(func():
		print("DISCONNECTING!")
		sig.disconnect(bridge.value)
	)
	
	bridge.value = cb2
	
	assert(sig.connect(cb2) == OK)

static func connect_lifetime(obj: Object, sig: Signal, cb: Callable) -> void:
	var stupid = obj
	Fn.connect_with_bail(sig, Fn.squash(func(args: Array):
		var bail = args.pop_back()
		if is_instance_valid(stupid):
			Fn.spread(cb).call(args)
		else:
			bail.call()
	))

static func unreachable() -> void:
	assert(false, "unreachable")

