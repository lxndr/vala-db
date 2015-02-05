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


public delegate void QueryCallback (Query query, int current, int total);


public abstract class Query : Object {
	public Database db { get; construct set; }
	private Gee.MultiMap<string, int> param_map;
	public Gee.List<unowned string?> columns;


	construct {
		param_map = new Gee.HashMultiMap<string, int> ();
		columns = new Gee.ArrayList<unowned string?> ();
	}


	protected abstract void native_prepare (string cmd) throws Error;
	protected abstract void native_bind_text (int index, string? val);
	protected abstract void native_bind_int (int index, int val);
	protected abstract void native_bind_int64 (int index, int64 val);
	protected abstract void native_bind_double (int index, double val);
	protected abstract unowned string[]? native_next () throws Error;
	protected abstract void native_reset ();


	public unowned Query prepare (string cmd) throws Error {
		debug ("Prepare '%s'", cmd);
		string prepared;

		try {
			int number = 0;
			var re = new Regex (":(.+?):");
			prepared = re.replace_eval (cmd, -1, 0, 0, (match_info, result) => {
				param_map[match_info.fetch (1)] = number;
				result.append_c ('?');
				number++;
				return false;
			});
		} catch (RegexError e) {
			error ("Failed to create a regular expression: %s", e.message);
		}

		native_prepare (prepared);
		return this;
	}


	public abstract unowned string command ();


	public unowned Query prepare_list (Type type) throws Error {
		var table = db.find_entity_spec (type).table_name;
		return prepare (@"SELECT * FROM `$(table)`");
	}


	public void exec () throws Error {
		debug ("Executing %s", command ());
		native_next ();
	}


	public void bind<T> (string name, T val) {
		var list = param_map[name];

		if (list.size == 0)
			error ("Could not find query parameter '%s'", name);

		var type = typeof (T);
		foreach (var index in list) {
			if (type == typeof (bool) || type == typeof (char) || type == typeof (uchar)
					|| type == typeof (int) || type == typeof (uint))
				native_bind_int (index, (int) val);
			else if (type == typeof (int64))
				native_bind_int64 (index, (int64) val);
			else if (type == typeof (uint64))
				native_bind_int64 (index, (int64) val);
/*			else if (type == typeof (float))
				native_bind_double (index, (double) (float) (int) val);
			else if (type == typeof (double))
				native_bind_double (index, (double) val);*/
			else if (type == typeof (string))
				native_bind_text (index, (string?) val);
			else if (val == null)
				native_bind_text (index, null);
			else if (type.is_a (typeof (SimpleEntity)))
				native_bind_int (index, ((SimpleEntity) val).id);
			else {
				string? s;
				var v = Value (typeof (T));
				v.set_instance (val);
				if (db.value_adapter.convert_to (out s, ref v, null, null))
					native_bind_text (index, s);
				else
					error ("Could not bind query parameter '%s', of type '%s'", name, type.name ());
			}
		}
	}


	public void bind_value (string name, ref Value val) {
		var list = param_map[name];

		if (list.size == 0)
			error ("Could not find query parameter '%s'", name);

		foreach (var index in list)
			bind_value_index (index, ref val);	
	}


	public void bind_value_index (int index, ref Value val) {
		var type = val.type ();

		if (type == typeof (char))
			native_bind_int (index, (int) val.get_schar ());
		else if (type == typeof (uchar))
			native_bind_int (index, (int) val.get_uchar ());
		else if (type == typeof (int))
			native_bind_int (index, (int) val.get_int ());
		else if (type == typeof (uint))
			native_bind_int (index, (int) val.get_uint ());
		else if (type == typeof (int64))
			native_bind_int64 (index, (int64) val.get_int64 ());
		else if (type == typeof (uint64))
			native_bind_int64 (index, (int64) val.get_uint64 ());
		else if (type == typeof (bool))
			native_bind_int (index, (int) val.get_boolean ());
		else if (type == typeof (float))
			native_bind_double (index, (double) val.get_float ());
		else if (type == typeof (double))
			native_bind_double (index, (double) val.get_double ());
		else if (type == typeof (string))
			native_bind_text (index, val.get_string ());
		else if (type.is_a (typeof (SimpleEntity)))
			native_bind_int (index, ((SimpleEntity) val.get_object ()).id);
		else {
			string? s;
			if (db.value_adapter.convert_to (out s, ref val, null, null))
				native_bind_text (index, s);
			else
				error ("Could not bind query parameter of type '%s'", type.name ());
		}
	}


	private T wrap_value<T> (ref Value val) {
		var t = typeof (T);
		if (t == typeof (bool))
			return val.get_boolean ();
		if (t == typeof (char))
			return val.get_schar ();
		if (t == typeof (int8))
			return val.get_schar ();
		if (t == typeof (uchar))
			return val.get_uchar ();
		if (t == typeof (int))
			return val.get_int ();
		if (t == typeof (uint))
			return val.get_uint ();
		if (t == typeof (long))
			return val.get_long ();
		if (t == typeof (ulong))
			return val.get_ulong ();
		if (t == typeof (int64))
			return val.get_int64 ();
		if (t == typeof (uint64))
			return val.get_uint64 ();
		/* TODO: float, double, string, boxed, object */
		return val.peek_pointer ();
	}



	/*
	 * Selection.
	 */
	public Gee.List<Entity> fetch_entity_list_full (Type type, QueryCallback? callback = null,
			Cancellable? cancellable = null) throws Error {
		var list = new Gee.ArrayList<Entity> ();

		while (!cancellable.is_cancelled ()) {
			var values = native_next ();
			if (values == null)
				break;

			list.add (make_entity_full (type, values));
		}

		native_reset ();
		return list;
	}


	public Gee.List<T> fetch_entity_list<T> (QueryCallback? callback = null, Cancellable? cancellable = null) throws Error {
		return fetch_entity_list_full (typeof (T), callback);
	}


	public Entity? fetch_entity_full (Type type) throws Error {
		var list = fetch_entity_list_full (type);
		if (list.size > 0)
			return list[0];
		return null;
	}


	public T? fetch_entity<T> () throws Error {
		return fetch_entity_full (typeof (T));
	}


	public T fetch_value<T> (T def) throws Error {
		var list = fetch_value_list<T> ();
		if (list.size > 0)
			return list[0];
		return def;
	}


	/**
	 * @brief Fetch a list of values of type @T.
	 * @query The query.
	 */
	public Gee.List<T> fetch_value_list<T> (QueryCallback? callback = null, Cancellable? cancellable = null) throws Error {
		var list = new Gee.ArrayList<T> ();

		while (!cancellable.is_cancelled ()) {
			var values = native_next ();
			if (values == null)
				break;

			var val = Value (typeof(T));
			if (!assemble_value (ref val, values[0]))
				warning ("-");
			list.add (wrap_value<T> (ref val));
		}

		native_reset ();
		return list;
	}


	public Gee.Map<K, T> fetch_entity_map<K, T> (string key_field,
			QueryCallback? callback = null, Cancellable? cancellable = null) throws Error {
		int key_column = -1;

		var map = new Gee.HashMap<K, T> ();
		while (!cancellable.is_cancelled ()) {
			var values = native_next ();
			if (values == null)
				break;

			if (key_column == -1) {
				for (var i = 0; i < columns.size; i++)
					if (columns[i] == key_field)
						key_column = i;
				if (key_column == -1)
					error (@"Doesn't have column '$(key_field)'");
			}

			var key_value = Value (typeof (K));
			assemble_value (ref key_value, values[key_column]);
			var key = wrap_value<K> (ref key_value);

			var val = make_entity<T> (values);
			map[key] = val;
		}

		native_reset ();
		return map;
	}


	public Gee.Map<K, V> fetch_value_map<K, V> (QueryCallback? callback = null, Cancellable? cancellable = null) throws Error {
		var map = new Gee.HashMap<K, V> ();
		while (!cancellable.is_cancelled ()) {
			var values = native_next ();
			if (values == null)
				break;

			var key_value = Value (typeof (K));
			assemble_value (ref key_value, values[0]);
			var key = wrap_value<K> (ref key_value);

			var val_value = Value (typeof (V));
			assemble_value (ref val_value, values[1]);
			var val = wrap_value<V> (ref val_value);

			map[key] = val;
		}

		native_reset ();
		return map;
	}


	public string? fetch_string (string? def) throws Error {
		return fetch_value<string?> (def);
	}


	/**
	 * One of most important functions in DB library.
	 * What does it do?
	 *     - if value is null, leaves property untouched;
	 *     - if property is an Entity, tries to fetch this entity from the database;
	 *     - if property is string, copies it;
	 *     - if property is something else, tries to convert it via g_value_transform.
	 */
	private void prepare_entity (Entity ent, string[] values) throws Error {
		var type = ent.get_type ();
		var obj_class = (ObjectClass) type.class_ref ();

		for (var i = 0; i < columns.size; i++) {
			unowned string? val = values[i];
			unowned string prop_name = columns[i];
			var prop = obj_class.find_property (prop_name);
			if (prop == null)
				error ("Could not find propery '%s.%s'", type.name (), prop_name);
			var prop_type = prop.value_type;

			var dest_val = Value (prop_type);
			if (!assemble_value (ref dest_val, val))
				warning ("Could not convert value '%s' from 'string' to '%s' for property '%s.%s'\n",
						val, prop_type.name (), type.name (), prop_name);

			ent.set_property (prop_name, dest_val);
		}
	}


	private bool assemble_value (ref Value val, string? str) throws Error {
		var type = val.type ();

		/* Entity */
		if (type.is_a (typeof (Entity))) {
			Entity? entity = null;
			if (str != null) {
				var entity_id = int.parse (str);
				if (entity_id > 0)
					entity = db.fetch_simple_entity_full (type, entity_id);
			}
			val.set_object (entity);
			return true;
		}

		/* String */
		if (type == typeof (string)) {
			val.set_string (str);
			return true;
		}

		/* Integer */
		if (type == typeof (int)) {
			if (str != null)
				val.set_int (int.parse (str));
			return true;
		}

		/* Integer 64 */
		if (type == typeof (int64)) {
			if (str != null)
				val.set_int64 (int64.parse (str));
			return true;
		}

		/* Boolean */
		if (type == typeof (bool)) {
			if (str != null)
				val.set_boolean (int.parse (str) > 0);
			return true;
		}

		/* Double */
		if (type == typeof (double)) {
			if (str != null)
				val.set_double (double.parse (str));
			return true;
		}

		/* Adapter */
		if (db.value_adapter.convert_from (ref val, str, null, null))
			return true;

		/* GLib transformer */
		if (str != null) {
			var tmp = Value (typeof (string));
			tmp.set_string (str);
			if (tmp.transform (ref val))
				return true;
		}

		val.unset ();
		return false;
	}


	public Entity make_entity_full (Type type, string[] values) throws Error {
		var ent = Object.new (type, "db", db) as Entity;
		prepare_entity (ent, values);
		return ent;
	}


	public T make_entity<T> (string[] values) throws Error {
		return make_entity_full (typeof (T), values);
	}
}


}
