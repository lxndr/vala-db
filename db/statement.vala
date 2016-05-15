namespace Db {


public abstract class Statement : Object, Gee.Iterable<Gee.List<string?>>, Gee.Traversable<Gee.List<string?>> {
	public Database db { get; construct set; }
	public Gee.List<string?> columns;

	construct {
		this.columns = new Gee.ArrayList<string?> ();
	}

	public abstract unowned string sql ();
	public abstract void prepare (string sql) throws GLib.Error;
	public abstract bool bind<T> (int index, T val) throws GLib.Error;
	public abstract void exec () throws GLib.Error;

	public abstract Gee.Iterator<Gee.List<string?>> iterator ();

	public bool @foreach (Gee.ForallFunc<Gee.List<string?>> f) {
		return this.iterator ().foreach (f);
	}
}


}

