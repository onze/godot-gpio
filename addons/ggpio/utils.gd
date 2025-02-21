
static func GetKeyForValue(v :String, d :Dictionary) -> Variant:
	for k :String in d:
		var dv :String = d.get(k)
		if v == dv:
			return k
	return ''

static func ParseDotEnv():
	var file := FileAccess.open('.env', FileAccess.READ)
	if file == null:
		return
	for line:String in file.get_as_text().split('\n'):
		if line.strip_edges().is_empty():
			continue
		var tokens := line.split('=')
		var key := tokens[0]
		var value := '='.join(tokens.slice(1))
		ggpio.log('[.ENV] %s=%s'%[key, value], ggpio.LogLevel.INFO)
		OS.set_environment(key, value)
