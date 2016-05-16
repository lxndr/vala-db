namespace Db {


private class Iterator : Object, Gee.Iterator<Gee.List<string?>>, Gee.Traversable<Gee.List<string?>> {
	private unowned Sqlite.Statement stmt;
	private Gee.List<string?> values;
	private bool begun = false;
	private bool done = false;


	public Iterator(Sqlite.Statement stmt) {
		this.stmt = stmt;
		this.stmt.reset ();
		this.values = new Gee.ArrayList<string?> ();
	}


	public bool valid {
		get { return this.begun; }
	}


	public bool read_only {
		get { return true; }
	}


	public bool next () {
		var ret = this.stmt.step ();

		switch (ret) {
		case Sqlite.ROW:
			return true;
		case Sqlite.DONE:
			this.done = true;
			return false;
		}

		return false;
	}


	public bool has_next () {
		return !this.done;
	}


	public new Gee.List<string?> @get () {
		this.values.clear ();
		var count = this.stmt.column_count ();
		for (var i = 0; i < count; i++)
			this.values.add(this.stmt.column_text (i));
		return this.values;
	}


	public bool @foreach (Gee.ForallFunc<Gee.List<string?>> f) {
		while (true) {
			var done = this.next ();
			if (done)
				return true;
			var row = this.@get ();
			if (!f (row))
				return false;
		}
	}


	public void remove () {

	}
}


private class SqliteStatement : Statement, Gee.Iterable<Gee.List<string?>> {
	private Sqlite.Statement native;


	public SqliteStatement (Database _db) {
		Object(db: _db);
	}


	public override unowned string? sql {
		get {
			return this.native == null ? null : this.native.sql ();
		}
	}


	public override void prepare (string sql) throws GLib.Error {
		unowned SqliteDatabase db = (SqliteDatabase) this.db;

		if (db.native ().prepare_v2 (sql, sql.length, out this.native) != Sqlite.OK)
		  throw db.get_error ();

		this.columns.clear ();
		var count = this.native.column_count ();
		for (var i = 0; i < count; i++)
		  this.columns.add (this.native.column_name (i));
	}


	public override bool bind<T> (int index, T val) throws GLib.Error {
		var type = typeof (T);
		int errcode = Sqlite.OK;
		index++; /* Sqlite counts from 1 */

		if (type == typeof (string))
			errcode = this.native.bind_text (index, (string) val);
		else if (type == typeof (int64) || type == typeof (uint64))
			errcode = this.native.bind_int64 (index, (int64) val);
		else if (is_decimal_type (type) || type == typeof (bool))
			errcode = this.native.bind_int (index, (int) val);
		// else if (is_float_type (type))
		// 	errcode = this.native.bind_double (index, (double) val);
		else
			return false;

		if (errcode != Sqlite.OK)
			throw ((SqliteDatabase) this.db).get_error ();

		return true;
	}


	public override void exec () throws GLib.Error {
		unowned SqliteDatabase db = (SqliteDatabase) this.db;
		if (this.native.reset () != Sqlite.OK)
			throw db.get_error ();
		if (this.native.step () != Sqlite.OK)
			throw db.get_error ();
	}


	public override Gee.Iterator<Gee.List<string?>> iterator () {
		return new Iterator (this.native);
	}
}


}
