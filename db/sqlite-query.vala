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


public class SqliteQuery : Query {
	private Sqlite.Statement native;
	private string[] values;


	public SqliteQuery (Database _db) {
		Object (db: _db);
	}


	protected override void native_prepare (string cmd) throws Error {
		unowned SqliteDatabase sqlite_db = (SqliteDatabase) db;
		if (sqlite_db.native ().prepare_v2 (cmd, -1, out native) != Sqlite.OK)
			throw new Error.NATIVE (sqlite_db.native ().errmsg ());

		var count = native.column_count ();
		columns.clear ();
		for (var i = 0; i < count; i++)
			columns.add (native.column_name (i));
	}


	public override unowned string command () {
		return native.sql ();
	}


	protected override unowned string[]? native_next () throws Error {
		if (native.step () != Sqlite.ROW)
			return null;

		var count = columns.size;
		if (count == 0)
			return null;

		values = new string[count];
		for (var i = 0; i < count; i++)
			values[i] = native.column_text (i);
		return values;
	}


	protected override void native_reset () {
		native.reset ();
	}


	protected override void native_bind_text (int index, string? val) {
		if (native.bind_text (index + 1, val) != Sqlite.OK)
			error (((SqliteDatabase) db).native ().errmsg ());
	}


	protected override void native_bind_int (int index, int val) {
		if (native.bind_int (index + 1, val) != Sqlite.OK)
			error (((SqliteDatabase) db).native ().errmsg ());
	}


	protected override void native_bind_int64 (int index, int64 val) {
		if (native.bind_int64 (index + 1, val) != Sqlite.OK)
			error (((SqliteDatabase) db).native ().errmsg ());
	}


	protected override void native_bind_double (int index, double val) {
		if (native.bind_double (index + 1, val) != Sqlite.OK)
			error (((SqliteDatabase) db).native ().errmsg ());
	}
}


}
