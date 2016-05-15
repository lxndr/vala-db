namespace Db {


public bool is_decimal_type (Type type) {
	Type[] types = {
		typeof (char), typeof (uchar),
		typeof (int), typeof (uint),
		typeof (long), typeof (ulong),
		typeof (short), typeof (ushort),
		typeof (int8), typeof (uint8),
		typeof (int16), typeof (uint16),
		typeof (int32), typeof (uint32),
		typeof (int64), typeof (uint64)
	};

	foreach (var t in types)
		if (t == type)
			return true;
	return false;
}


public bool is_float_type (Type type) {
	return type == typeof (float) || type == typeof (double);
}


}
