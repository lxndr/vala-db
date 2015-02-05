/*
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public
 *  License along with this library. If not, see <http://www.gnu.org/licenses/>.
 */


namespace DB {


public delegate bool ValueAdapterFromFunc (ref Value v, string? s);
public delegate bool ValueAdapterToFunc (out string? s, ref Value v);


private struct Adapter {
	Type type;
	string? table;
	string? column;
	unowned ValueAdapterFromFunc from_func;
	unowned ValueAdapterToFunc to_func;
}


public class ValueAdapter {
	private Gee.List<Adapter?> adapters;


	public ValueAdapter () {
		adapters = new Gee.ArrayList<Adapter?> ();
	}


	public void register (Type type, string? column, ValueAdapterFromFunc? from_fn, ValueAdapterToFunc? to_fn)
			requires (type != Type.INVALID || column != null) {
		adapters.add ({type, null, column, from_fn, to_fn});
	}


	private Adapter? find_spec (Type type, string? table, string? column) {
		foreach (var adapter in adapters)
			if (adapter.from_func != null &&
					(adapter.type == Type.INVALID || adapter.type == type) &&
					(adapter.table == null || adapter.table == table) &&
					(adapter.column == null || adapter.column == column))
				return adapter;
		return null;
	}


	public bool convert_from (ref Value v, string? s, string? table, string? column) {
		var spec = find_spec (v.type (), table, column);
		if (unlikely (spec == null))
			return false;
		return spec.from_func (ref v, s);
	}


	public bool convert_to (out string? s, ref Value v, string? table, string? column) {
		var spec = find_spec (v.type (), table, column);
		if (spec != null)
			return spec.to_func (out s, ref v);
		s = null;
		return false;
	}
}


}
