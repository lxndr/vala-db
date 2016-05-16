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


/**
 * 
 */
public abstract class Statement : Object, Gee.Iterable<Gee.List<string?>>, Gee.Traversable<Gee.List<string?>> {
	public Database db { get; construct set; }
	public Gee.List<string?> columns { get; private set; }
	public abstract unowned string? sql { get; }

	construct {
		this.columns = new Gee.ArrayList<string?> ();
	}

	public abstract void prepare (string sql) throws GLib.Error;
	public abstract bool bind<T> (int index, T val) throws GLib.Error;
	public abstract void exec () throws GLib.Error;

	public abstract Gee.Iterator<Gee.List<string?>> iterator ();

	public bool @foreach (Gee.ForallFunc<Gee.List<string?>> f) {
		return this.iterator ().foreach (f);
	}
}


}

