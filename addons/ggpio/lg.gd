'''
Static lg API
'''

static func FL(pat :String, num :int) -> LGCommand:
	return LGCommand.new('-a').append_array(['fl', pat, String.num_int64(num)])

static func GO(gc :String, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['go', gc])

static func GC(h :String, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gc', h])

static func GIC(h :String, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gic', h])

static func GSI(h :String, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gsi', h, String.num_int64(g)])

static func GSIX(h :String, lf :ggpio.LineFlag, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gsix', h, String.num(lf), String.num_int64(g)])

static func GSO(h :String, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gso', h, String.num_int64(g)])

static func GSOX(h :String, lf :ggpio.LineFlag, g :int, v :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gsox', h, String.num(lf), String.num_int64(g), String.num_int64(v)])

static func GSF(h :String, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gsf', h, String.num_int64(g)])

static func GIL(h :String, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gil', h, String.num_int64(g)])

static func GMODE(h :String, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gmode', h, String.num_int64(g)])

static func GR(h :String, g :int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gr', h, String.num_int64(g)])

static func GW(h :String, g :int, v: int, share_id :int = ggpio.NO_SHARE) -> LGCommand:
	return LGCommand.new().share(share_id).append_array(['gw', h, String.num_int64(g), String.num_int64(v)])


class LGCommand:
	var tokens := PackedStringArray()
	var rgs_flags := ''

	func _init(rgs_flags := '') -> void:
		self.rgs_flags = rgs_flags

	func append(token :String) -> LGCommand:
		tokens.append(token)
		return self

	func append_array(tokens :PackedStringArray) -> LGCommand:
		self.tokens.append_array(tokens)
		return self

	func share(share_id :int)-> LGCommand:
		if share_id != ggpio.NO_SHARE:
			tokens.append('c')
			tokens.append(String.num_int64(share_id))
		return self

	func run(sbc :ggpio.SBC = null) -> Array:
		'''
		Returns [Error, String].
		'''
		if sbc != null:
			OS.set_environment('LG_ADDR', sbc.host)
			OS.set_environment('LG_PORT', sbc.port)
		var output :Array[String] = []
		ggpio.log('[CMD] %s'%[' '.join(tokens)], ggpio.LogLevel.VERBOSE)
		var args := PackedStringArray()
		if not rgs_flags.is_empty():
			args.append(rgs_flags)
		args.append_array(tokens)
		var rcode := OS.execute('rgs', args, output, true, false)
		var err := OK if rcode == 0 else FAILED
		if err != OK:
			ggpio.log(
				'Error running command "%s" (rcode %s/%s): %s'%[
					args,
					rcode,
					ggpio.ErrorCodes.get(rcode, ''),
					output.back() if output.size()>1 else '<empty stderr>'
				],
				ggpio.LogLevel.WARNING
			)
		return [err, output[0].strip_edges()]
