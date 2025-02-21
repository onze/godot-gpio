
static func GetKeyForValue(v :String, d :Dictionary) -> Variant:
	for k :String in d:
		var dv :String = d.get(k)
		if v == dv:
			return k
	return ''
