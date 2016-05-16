namespace Db {


private class MysqlStatement : Statement {
	private string _sql;


	public override unowned string? sql {
		get {
			return this._sql;
		}
	}


	public override void prepare (string sql) throws GLib.Error {
		this._sql = sql;
	}


	public override bool bind<T> (int index, T val) throws GLib.Error {
		return false;
	}


	public override void exec () throws GLib.Error {

	}


	public override Gee.Iterator<Gee.List<string>> iterator () {
		return new Gee.ArrayList<Gee.List<string>> ().iterator ();
	}
}


}
