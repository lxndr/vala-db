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


namespace Db {


public delegate void QueryCallback (Query query, Entity entity, int number);


public class Query : Object {
	static Regex re_names;
	public Database db { get; construct set; }
	private Statement statement;
	private Gee.MultiMap<string, int> param_map;


	static construct {
		try {
			re_names = new Regex (":(\\w+)", RegexCompileFlags.OPTIMIZE);
		} catch (GLib.Error err) {
			error ("Failed to parse command due to regexp error: %s", err.message);
		}
	}


	construct {
		this.param_map = new Gee.HashMultiMap<string, int> ();
	}


	public Query(Database _db, Type stmt_type) {
		Object(db: _db);
		this.statement = (Statement) Object.new (stmt_type);
	}


	public unowned Query prepare (string sql) throws GLib.Error {
		int number = 0;

		sql = re_names.replace_eval (sql, -1, 0, 0, (match_info, result) => {
			param_map[match_info.fetch (1)] = number;
			result.append_c ('?');
			number++;
			return false;
		});

		this.statement.prepare (sql);
		return this;
	}


	public unowned string sql () {
		return this.statement.sql ();
	}


	public void exec () throws GLib.Error {
		debug ("Executing %s", this.sql ());
		this.statement.exec ();
	}


	public void bind<T> (string name, T val) throws GLib.Error {
		var list = this.param_map[name];

		if (list.size == 0)
			throw new Error.GENERIC ("Could not find query parameter '%s'", name);

		var type = typeof (T);
		foreach (var index in list) {
			if (this.statement.bind<T> (index, val))
				continue;

			if (type.is_a (typeof (SimpleEntity))) {
				this.statement.bind<int> (index, ((SimpleEntity) val).id);
			} else {
				string? s;
				var v = Value (typeof (T));
				v.set_instance (val);
				if (this.db.value_adapter.convert_to (out s, ref v, null, null))
					this.statement.bind<string> (index, s);
				else
					error ("Could not bind query parameter '%s', of type '%s'", name, type.name ());
			}
		}
	}


	/**
	 *
	 */
	public void bind_value (string name, ref Value val) {

	}


	public unowned Query prepare_list (Type type) throws GLib.Error {
		var table = this.db.find_entity_spec (type).table_name;
		return this.prepare (@"SELECT * FROM `$(table)`");
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
			Cancellable? cancellable = null) throws GLib.Error {
		var list = new Gee.ArrayList<Entity> ();

		foreach (var values in this.statement) {
			if (cancellable.is_cancelled ())
				break;

			var entity = this.make_entity_full (type, values);
			list.add (entity);

			if (callback != null)
				callback (this, entity, list.size - 1);
		}

		return list;
	}


	public Gee.List<T> fetch_entity_list<T> (QueryCallback? callback = null, Cancellable? cancellable = null) throws GLib.Error {
		return fetch_entity_list_full (typeof (T), callback);
	}


	public Entity? fetch_entity_full (Type type) throws GLib.Error {
		var list = fetch_entity_list_full (type);
		if (list.size > 0)
			return list[0];
		return null;
	}


	public T? fetch_entity<T> () throws GLib.Error {
		return fetch_entity_full (typeof (T));
	}


	public T fetch_value<T> (T def) throws GLib.Error {
		var list = fetch_value_list<T> ();
		if (list.size > 0)
			return list[0];
		return def;
	}


	/**
	 * @brief Fetch a list of values of type @T.
	 * @query The query.
	 */
	public Gee.List<T> fetch_value_list<T> (QueryCallback? callback = null, Cancellable? cancellable = null) throws GLib.Error {
		var list = new Gee.ArrayList<T> ();

		foreach (var values in this.statement) {
			if (cancellable.is_cancelled ())
				break;

			var val = Value (typeof(T));
			if (!this.assemble_value (ref val, values[0]))
				warning ("-");
			list.add (wrap_value<T> (ref val));
		}

		return list;
	}


	/**
	 *
	 */
	public Gee.Map<K, T> fetch_entity_map<K, T> (string key_field,
			QueryCallback? callback = null, Cancellable? cancellable = null) throws GLib.Error {
		int key_column = this.statement.columns.index_of (key_field);
		if (key_column == -1)
			throw new Error.GENERIC (@"Doesn't have column '$(key_field)'");

		var map = new Gee.HashMap<K, T> ();
		foreach (var values in this.statement) {
			if (cancellable.is_cancelled ())
				break;

			var key_value = Value (typeof (K));
			this.assemble_value (ref key_value, values[key_column]);
			var key = this.wrap_value<K> (ref key_value);

			var val = this.make_entity<T> (values);
			map[key] = val;
		}

		return map;
	}


	/**
	 *
	 */
	public Gee.Map<K, V> fetch_value_map<K, V> (QueryCallback? callback = null, Cancellable? cancellable = null) throws GLib.Error {
		var map = new Gee.HashMap<K, V> ();
		foreach (var values in this.statement) {
			if (cancellable.is_cancelled ())
				break;

			var key_value = Value (typeof (K));
			this.assemble_value (ref key_value, values[0]);
			var key = this.wrap_value<K> (ref key_value);

			var val_value = Value (typeof (V));
			this.assemble_value (ref val_value, values[1]);
			var val = this.wrap_value<V> (ref val_value);

			map[key] = val;
		}

		return map;
	}


	public string? fetch_string (string? def) throws GLib.Error {
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
	private void prepare_entity (Entity ent, Gee.List<string?> values) throws GLib.Error {
		var type = ent.get_type ();
		var obj_class = (ObjectClass) type.class_ref ();
		unowned Gee.List<unowned string> columns = this.statement.columns;

		for (var i = 0; i < this.statement.columns.size; i++) {
			var val = values[i];
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


	private bool assemble_value (ref Value val, string? str) throws GLib.Error {
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


	public Entity make_entity_full (Type type, Gee.List<string?> values) throws GLib.Error {
		var ent = Object.new (type, "db", db) as Entity;
		this.prepare_entity (ent, values);
		return ent;
	}


	public T make_entity<T> (Gee.List<string?> values) throws GLib.Error {
		return this.make_entity_full (typeof (T), values);
	}
}


}
