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


[Compact]
public class QueryBuilder {
	public StringBuilder sb;
	public bool have_where;
	public bool have_on;


	public QueryBuilder () {
		sb = new StringBuilder.sized (64);
	}


	public unowned QueryBuilder select (string? expr = null) {
		sb.printf ("SELECT %s", expr ?? "*");
		return this;
	}


	public unowned QueryBuilder delete (string table) {
		sb.printf ("DELETE FROM %s", table);
		return this;
	}


	public string done () {
		return sb.str;
	}


	public unowned QueryBuilder from (string expr) {
		sb.append_printf (" FROM %s", expr);
		return this;
	}


	public unowned QueryBuilder join (string expr) {
		sb.append_printf (" JOIN %s", expr);
		have_on = false;
		return this;
	}


	public unowned QueryBuilder on (string expr) {
		if (have_on)
			sb.append_printf (" AND (%s)", expr);
		else
			sb.append_printf (" ON (%s)", expr);
		have_on = true;
		return this;
	}


	public unowned QueryBuilder where (string expr) {
		if (have_where)
			sb.append_printf (" AND (%s)", expr);
		else
			sb.append_printf (" WHERE (%s)", expr);
		have_where = true;
		return this;
	}


	public unowned QueryBuilder group_by (string column) {
		sb.append_printf (" GROUP BY %s", column);
		return this;
	}


	public unowned QueryBuilder order_by (string column) {
		sb.append_printf (" ORDER BY %s", column);
		return this;
	}


	public unowned QueryBuilder limit (int limit) {
		sb.append_printf (" LIMIT %d", limit);
		return this;
	}
}


}
