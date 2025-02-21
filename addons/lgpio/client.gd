#extends Node

#
##region setup
#@export var host :String = ''
#@export var port :int = 8888
##endregion
#
##region public interface
#var is_connected :bool:
	#get: return _socket != null and _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED
#signal connected()
#signal disconnected()
##endregion
#
#
#var _socket :StreamPeerTCP = null
#var _response_signals :Array[Signal] = []
#var _response_signal_id := 0
#var _data_buffer := PackedByteArray()
#
#func _ready() -> void:
	#if not host.is_empty():
		#connect_to_host(host, port)
#
#func connect_to_host(host_ :String, port_ :int = 8888) -> void:
	#lgpio._log('connecting...', lgpio.LogLevel.DEBUG)
	#if is_connected:
		#if _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			#lgpio._log('disconnecting first...', lgpio.LogLevel.DEBUG)
			#_socket.disconnect_from_host()
		#_socket = null
	#host = host_
	#port = port_
	#assert(not host.is_empty())
	#assert(port > 0 and port < 65535)
	#_socket = StreamPeerTCP.new()
	#var err := _socket.connect_to_host(host, port)
	#if err != OK:
		#lgpio._log('Could not connect: %s/%s'%[error_string(err), err], lgpio.LogLevel.WARNING)
		#disconnected.emit()
#
#func _process(delta: float) -> void:
	#if _socket != null:
		#var last_status = _socket.get_status()
		#_socket.poll()
		#match _socket.get_status():
			#StreamPeerTCP.STATUS_NONE:
				#if last_status in [StreamPeerTCP.STATUS_CONNECTED, StreamPeerTCP.STATUS_CONNECTING]:
					#lgpio._log('Disconnected', lgpio.LogLevel.DEBUG)
					#disconnected.emit()
			#StreamPeerTCP.STATUS_CONNECTING:
				#pass
			#StreamPeerTCP.STATUS_CONNECTED:
				#if last_status in [StreamPeerTCP.STATUS_NONE, StreamPeerTCP.STATUS_CONNECTING]:
					#_socket.set_no_delay(true)
					#lgpio._log('connected', lgpio.LogLevel.DEBUG)
					#connected.emit()
				#_pull_messages()
			#StreamPeerTCP.STATUS_ERROR:
				#lgpio._log('Could not connect', lgpio.LogLevel.DEBUG)
				#disconnected.emit()
				#_socket = null
				#pass
#
#func _pull_messages() -> void:
	#var available_bytes := _socket.get_available_bytes()
	#if available_bytes == 0:
		#return
	#var ret := _socket.get_data(available_bytes)
	#var err :Error = ret[0]
	#if err != OK:
		#return lgpio._log(
			#'Error reading from lgpio server: %s/%s'%[error_string(err), err],
			#lgpio.LogLevel.ERROR
		#)
#
	#_data_buffer += ret[1]
	#_data_buffer.clear()
	#return
	#lgpio._log('< %s'%_data_buffer, lgpio.LogLevel.DEBUG)
	#while not _data_buffer.is_empty():
		#var response :Array[int] = [
			#_data_buffer.decode_u32(0),
			#_data_buffer.decode_u32(4),
			#_data_buffer.decode_u32(8),
			#_data_buffer.decode_u32(12),
		#]
		#_data_buffer = _data_buffer.slice(16)
#
#
	##var last_break_index = _data_buffer.rfind('\n')
	##if last_break_index == -1:
		##last_break_index = _data_buffer.length()
	##var index = 0
	##while index < last_break_index:
		##var break_index = _data_buffer.find('\n', index)
		##if break_index == -1:
			##break
		##var line = _data_buffer.get_slice(index, break_index)
		##if _response_signals.is_empty():
			##lgpio._log('Unexpected lgpio server data: %s'%_data_buffer, lgpio.LogLevel.WARNING)
			##continue
		##var sig :Signal = _response_signals.pop_back()
		##if sig.is_null():
			### caller wasn't interested in the result
			##continue
		##sig.emit(line.strip_edges())
		##index = break_index
	### now remove everything but the last line
	##if last_break_index < _data_buffer.length():
		##_data_buffer = _data_buffer.get_slice(last_break_index, 0)
	##else:
		##_data_buffer = ''
#
#func _socket_response_signal() -> Signal:
	#var sig_name := 'socket_response_signal_%d'%_response_signal_id
	#add_user_signal(
		#sig_name,
		#[
			#{ "name": "bytes", "type": TYPE_PACKED_BYTE_ARRAY }
		#]
	#)
	#_response_signal_id += 1
	#var sig := Signal(self, sig_name)
	#_response_signals.push_back(sig)
	#return sig
#
#func send(
	#cmd :lgpio.Command,
	#p1 :int,
	#p2 :int = 0,
	#p3 :int = 0,
	#extension :PackedByteArray = []
#) -> Array:
	#if not is_connected:
		#push_error('PigPIOClient needs to be connected before it can send commands.')
		#return PackedByteArray()
	#var data := PackedByteArray(
		##[cmd, p1, p2, p3]
	#)
	#data.resize(4*4)
	#data.encode_u32(0, cmd)
	#data.encode_u32(4, p1)
	#data.encode_u32(8, p2)
	#data.encode_u32(12, p3)
	#if p3 != 0:
		#data.append_array(extension)
	#lgpio._log('> %s'%[[cmd, p1, p2, p3]], lgpio.LogLevel.DEBUG)
	#_socket.put_data(data)
	#return await _socket_response_signal()
#
##func _wait_for_bytes() -> Array:
	##var tt := Time.get_unix_time_from_system()
	##while _socket.get_available_bytes() < lgpio._SOCK_CMD_LEN:
		##_socket.poll()
		##if Time.get_unix_time_from_system()-tt > lgpio._SOCK_RESPONSE_TIMEOUT_S:
			##printerr('_wait_for_bytes(): timeout')
			##return [ERR_TIMEOUT, PackedByteArray()]
	##return [OK, _socket.get_data(_socket.get_available_bytes())]
#
#func pin(gpio :int, mode := lgpio.Mode.BAD_MODE) -> lgpio.Pin:
	#return lgpio.Pin.new(self, gpio, mode)
