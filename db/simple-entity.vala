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


public abstract class SimpleEntity : Entity {
	public int id { get; set; default = 0; }


	construct {
		id = 0;
	}


	public override unowned string[] db_keys () {
		const string keys[] = {
			"id"
		};
		return (string[]) keys;
	}


	public override void persist () throws Error {
		unowned string tbl_name = db_table ();
		DB.Query query;

		if (id == 0) {
			if (!db.get_query (@"$(tbl_name)-insert", out query)) {
				var sb = new StringBuilder ();
				foreach (unowned string prop_name in db_fields ())
					sb.append_printf (":%s:, ", prop_name);
				sb.truncate (sb.len - 2);
				query.prepare (@"INSERT INTO `$(tbl_name)` VALUES (NULL, $(sb.str))");
			}

			bind_properties (query, db_fields ());
			query.exec ();
			id = db.last_insert_rowid ();
		} else {
			if (!db.get_query (@"$(tbl_name)-update", out query)) {
				var sb = new StringBuilder ();
				foreach (unowned string prop_name in db_fields ())
					sb.append_printf ("%s = :%s:, ", prop_name, prop_name);
				sb.truncate (sb.len - 2);
				query.prepare (@"UPDATE `$(tbl_name)` SET $(sb.str) WHERE id = :id:");
			}

			bind_properties (query, db_fields ());
			query.bind<int> ("id", id);
			query.exec ();
		}
	}
}


}
