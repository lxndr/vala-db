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


public abstract class Database : Object {
	public string stamp_table { get; construct set; }


	public ValueAdapter value_adapter { get; set; }
	private Gee.Map<Type, unowned EntitySpec> entity_types;
	private Gee.Map<string, Query> query_list;


	construct {
		this.entity_types = new Gee.HashMap<Type, EntitySpec> ();
		this.query_list = new Gee.HashMap<string, Query> ();

		if (this.stamp_table == null)
			this.stamp_table = "stamp";
	}


	protected abstract Type statement_type ();
	public abstract int last_insert_id ();


	/**
	 * Register entity type.
	 */
	public unowned EntitySpec register_entity_type (Type type, string table_name) {
		entity_types[type] = new EntitySpec (type, table_name);
		return entity_types[type];
	}


  /**
   * Unregister entity type.
   */
	public void unregister_entity_type (Type type) {
		entity_types.unset (type);
	}


	public unowned EntitySpec? find_entity_spec (Type type) {
		if (entity_types.has_key (type))
			return entity_types[type];
		return null;
	}


	public Query new_query (string? sql = null) throws GLib.Error {
		var query = new Query (this, this.statement_type ());
		if (sql != null)
			query.prepare (sql);
		return query;
	}


	/**
	 * 
	 */
	public bool get_query (string name, out Query query) throws GLib.Error {
		query = query_list[name];
		if (query == null) {
			query = new_query ();
			query_list[name] = query;
			return false;
		}

		return true;
	}


	/**
	 * 
	 */
	public int query_count (string from, string where) throws GLib.Error {
		var q = new_query ();
		q.prepare (@"SELECT COUNT(*) FROM $(from) WHERE $(where)");
		return q.fetch_value<int> (0);
	}


	/**
	 * Fetch simple entity by id.
	 * @param type of the entity to create.
	 * @param id of the entity to fetch from the database.
	 * @param table to query.
	 */
	public Entity? fetch_simple_entity_full (Type type, int id, string? table = null) throws GLib.Error {
		if (table == null) {
			unowned EntitySpec? spec = find_entity_spec (type);
			if (spec == null)
				throw new Error.GENERIC ("Could not find spec for '%s'", type.name ());
			table = spec.table_name;
		}

		var q = new_query ();
		q.prepare (@"SELECT * FROM `$(table)` WHERE id = $(id)");
		return q.fetch_entity_full (type);
	}


	/**
	 * Fetch simple entity by id. Template version.
	 * @param id of the entity to fetch from the database.
	 * @param table to query.
	 */
	public T? fetch_simple_entity<T> (int id, string? table = null) throws GLib.Error {
		return fetch_simple_entity_full (typeof (T), id, table);
	}


	/*
	 *	Change tracking.
	 */
	public bool is_table_changed (ref int stamp, string table) throws GLib.Error {
		Db.Query query;
		if (!get_query ("get-table-stamp", out query))
			query.prepare ("SELECT value FROM %s WHERE name = '%s'".printf (stamp_table, table));
		var new_stamp = query.fetch_value<int> (0);
		var ret = stamp != new_stamp;
		stamp = new_stamp;
		return ret;
	}


	public virtual string? escape_string (string? s) {
		if (s == null)
			return null;
		return s.replace ("'", "''");
	}


	/**
	 * Begin transaction.
	 */
	public virtual void begin_transaction () throws GLib.Error {
		new_query ("BEGIN TRANSACTION").exec ();
	}


	/**
	 * Commit.
	 */
	public virtual void commit () throws GLib.Error {
		new_query ("COMMIT").exec ();
	}


	/**
	 * Rollback.
	 */
	public virtual void rollback () throws GLib.Error {
		new_query ("ROLLBACK").exec ();
	}
}


}
