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


/*
 * This is simply a wrapper for GLib.Date
 * to make it fully functional, nullable property,
 * and gather all date functionality in one class.
 */
public class Date {
	private GLib.Date date;


	public Date.from_ymd (DateYear _year, DateMonth _month, DateDay _day) {
		date.set_dmy (_day, _month, _year);
	}


	public Date.from_days (int _days) {
		date.set_julian (_days);
	}


	public Date.now () {
		int year;
		int month;
		int day;

		var now = new DateTime.now_local ();
		now.get_ymd (out year, out month, out day);
		date.set_dmy ((DateDay) day, month, (DateYear) year);
	}


	public static Date? parse (string str) {
		var tmp = GLib.Date ();
		tmp.set_parse (str);
		if (!tmp.valid ())
			return null;

		var date = new Date ();
		date.date = tmp;
		return date;
	}


	public void to_ymd (out DateYear year, out DateMonth month, out DateDay day) {
		year = date.get_year ();
		month = date.get_month ();
		day = date.get_day ();
	}


	public unowned Date assign (Date that) {
		date = that.date;
		return this;
	}


	public int compare (Date that) {
		return (int) date.get_julian () - (int) that.date.get_julian ();
	}


	public int diff (Date that) {
		return compare (that).abs ();
	}


	public static void clamp_range (ref Date? first, ref Date? last, Date? min, Date? max) {
		/* no dates */
		if (first == null && last == null)
			return;

		if (min != null) {
			if (last != null && last.compare (min) < 0) {
				/* out of range */
				first = null;
				last = null;
				return;
			}

			if (first == null || first.compare (min) < 0)
				first = min;
		}

		if (max != null) {
			if (first != null && first.compare (max) > 0) {
				/* out of range */
				first = null;
				last = null;
				return;
			}

			if (last == null || last.compare (max) > 0)
				last = max;
		}
	}


	public string? format () {
		if (date.valid ()) {
			char buf[32];
			date.strftime (buf, "%x");
			return (string) buf;
		}

		return null;
	}


	/* value adapter */
	public static bool string_to_value (ref Value v, string? s) {
		if (s == null)
			return true;

		var list = s.split ("-");
		if (list.length < 3)
			return true;

		var date = new Date.from_ymd (
				(DateYear) int.parse (list[0]),
				(DateMonth) int.parse (list[1]),
				(DateDay) int.parse (list[2]));
		v.set_instance (date);
		return true;		
	}


	public static bool value_to_string (out string? s, ref Value v) {
		var date = (Date) v.peek_pointer ();
		if (date == null)
			s = null;
		else {
			DateYear year;
			DateMonth month;
			DateDay day;
			date.to_ymd (out year, out month, out day);
			s = "%04d-%02d-%02d".printf ((int) year, (int) month, (int) day);
		}

		return true;
	}
}


}
