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


public abstract class Database : Object {
	public ValueAdapter value_adapter { get; set; }
	private Gee.Map<Type, unowned EntitySpec> entity_types;
	private Gee.Map<string, Query> query_list;


	construct {
		entity_types = new Gee.HashMap<Type, EntitySpec> ();
		query_list = new Gee.HashMap<string, Query> ();
	}


	public abstract Query new_query ();
	public abstract int last_insert_rowid ();
	public abstract string? escape_string (string? s);


	/*
	 * Entity specs registry.
	 */
	public unowned EntitySpec register_entity_type (Type type, string table_name) {
		entity_types[type] = new EntitySpec (type, table_name);
		return entity_types[type];
	}


	public void unregister_entity_type (Type type) {
		entity_types.unset (type);
	}


	public unowned EntitySpec? find_entity_spec (Type type) {
		if (entity_types.has_key (type))
			return entity_types[type];
		return null;
	}


	public bool get_query (string name, out Query query) {
		query = query_list[name];
		if (query == null) {
			query = new_query ();
			query_list[name] = query;
			return false;
		}

		return true;
	}


	public int query_count (string from, string where) throws Error {
		var q = new_query ();
		q.prepare (@"SELECT COUNT(*) FROM $(from) WHERE $(where)");
		return q.fetch_value<int> (0);
	}


	public Entity? fetch_simple_entity_full (Type type, int id, string? table = null) throws Error {
		if (table == null) {
			unowned EntitySpec? spec = find_entity_spec (type);
			if (spec == null)
				error ("Could not find spec for '%s'", type.name ());
			table = spec.table_name;
		}

		var q = new_query ();
		q.prepare (@"SELECT * FROM `$(table)` WHERE id = $(id)");
		return q.fetch_entity_full (type);
	}


	public T? fetch_simple_entity<T> (int id, string? table = null) throws Error {
		return fetch_simple_entity_full (typeof (T), id, table);
	}


	/*
	 *	Transaction control.
	 */
	public void begin_transaction () throws Error {
		var query = new_query ();
		query.prepare ("BEGIN TRANSACTION").exec ();
	}


	public void commit_transaction () throws Error {
		var query = new_query ();
		query.prepare ("COMMIT TRANSACTION").exec ();
	}


	public void rollback_transaction () throws Error {
		var query = new_query ();
		query.prepare ("ROLLBACK TRANSACTION").exec ();
	}
}


}
