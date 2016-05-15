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


public class SqliteDatabase : Database, Initable {
	public File file { get; construct set; }
	private Sqlite.Database _native;


	public SqliteDatabase (File _file) throws GLib.Error {
		Object (file: _file);
		((Initable) this).init (null);
	}


	private bool init (Cancellable? cancellable = null) throws GLib.Error {
		int ret = Sqlite.Database.open_v2 (file.get_path (), out this._native);
		if (ret != Sqlite.OK) {
			throw new Error.NATIVE ("Error opening the database at '%s': (%d) %s",
				file.get_path (), this._native.errcode (), this._native.errmsg ());
		}

		return true;
	}


	public unowned Sqlite.Database native () {
		return this._native;
	}


	public Error get_error () {
		return new Error.NATIVE (this._native.errmsg ());
	}


	protected override Type statement_type () {
		return typeof (SqliteStatement);
	}


	public override int last_insert_id () {
		return (int) this._native.last_insert_rowid ();
	}
}


}

