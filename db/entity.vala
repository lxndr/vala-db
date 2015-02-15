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


public abstract class Entity : Object {
	public Database db { get; construct set; }


	public unowned string db_table () {
		return db.find_entity_spec (get_type ()).table_name;
	}


	public abstract unowned string[] db_keys ();
	public abstract unowned string[] db_fields ();


	public virtual void remove () throws GLib.Error {
		DB.Query query;

		if (db_keys ().length == 0) {
			warning (@"Cannot delete entity $(get_type ()) that does not have primary key");
			return;
		}

		unowned string tbl_name = db_table ();
		if (!db.get_query (@"$(tbl_name)-delete", out query)) {
			var builder = new DB.QueryBuilder ();
			builder.delete (tbl_name);
			foreach (unowned string prop_name in db_keys ())
				builder.where (@"$(prop_name) = :$(prop_name):");
			query.prepare (builder.done ());
		}

		bind_properties (query, db_keys ());
		query.exec ();
	}


	public virtual void persist () throws GLib.Error {
		DB.Query query;

		unowned string tbl_name = db_table ();
		if (!db.get_query (@"$(tbl_name)-replace", out query)) {
			var sb = new StringBuilder ();
			foreach (unowned string prop_name in db_keys ())
				sb.append_printf (":%s:, ", prop_name);
			foreach (unowned string prop_name in db_fields ())
				sb.append_printf (":%s:, ", prop_name);
			sb.truncate (sb.len - 2);
			query.prepare (@"REPLACE INTO `$(tbl_name)` VALUES ($(sb.str))");
		}

		bind_properties (query, db_keys ());
		bind_properties (query, db_fields ());
		query.exec ();
	}


	protected void bind_properties (Query query, string[] props) {
		unowned ObjectClass obj_class = (ObjectClass) get_type ().class_peek ();
		foreach (unowned string prop_name in props) {
			unowned ParamSpec? prop_spec = obj_class.find_property (prop_name);
			var val = Value (prop_spec.value_type);
			get_property (prop_name, ref val);
			query.bind_value (prop_name, ref val);
		}
	}
}


public class EntitySpec {
	public Type type;
	public string table_name;


	public EntitySpec (Type _type, string _table_name) {
		type = _type;
		table_name = _table_name;
	}
}


}
