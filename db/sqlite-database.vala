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


public class SqliteDatabase : Database {
	public File file { get; construct set; }
	private Sqlite.Database _native;


	construct {
		int ret = Sqlite.Database.open_v2 (file.get_path (), out _native);
		if (ret != Sqlite.OK)
			error ("Error opening the database at '%s': (%d) %s",
					file.get_path (), _native.errcode (), _native.errmsg ());
	}


	public SqliteDatabase (File _file) {
		Object (file: _file);
	}


	public unowned Sqlite.Database native () {
		return _native;
	}


	public override int last_insert_rowid () {
		return (int) _native.last_insert_rowid ();
	}


	public override string? escape_string (string? s) {
		if (s == null)
			return null;
		return s.replace ("'", "''");		
	}


	public override Query new_query () {
		return new SqliteQuery (this);
	}
}


}
