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


public class Month {
	public int integer { get; set; }


	public DateYear year {
		get { return (DateYear) (integer / 12); }
	}


	public DateMonth month {
		get { return (DateMonth) (integer % 12 + 1); }
	}


	public Date? first_day {
		owned get {
			if (unlikely (integer == 0))
				return null;
			else
				return new Date.from_ymd (year, month, 1);
		}
	}


	public Date? last_day {
		owned get {
			if (unlikely (integer == 0))
				return null;
			var m = month;
			return new Date.from_ymd (year, m, m.get_days_in_month (year));
		}
	}


	public Month.copy (Month that) {
		integer = that.integer;
	}


	public Month.from_integer (int _integer) {
		integer = _integer;
	}


	public Month.from_year_month (DateYear _year, DateMonth _month) {
		integer = (int) _year * 12 + (int) _month - 1;
	}


	public Month.now () {
		var date = new DateTime.now_local ();
		integer = (int) date.get_year () * 12 + (int) date.get_month () - 1;
	}


	public unowned Month assign (Month that) {
		integer = that.integer;
		return this;
	}


	public void prev () {
		integer -= 1;
	}


	public void next () {
		integer += 1;
	}


	public Month get_prev () {
		return new Month.from_integer (integer - 1);
	}


	public Month get_next () {
		return new Month.from_integer (integer + 1);
	}


	public Month get_first_month () {
		return new Month.from_year_month (year, DateMonth.JANUARY);
	}


	public Month get_last_month () {
		return new Month.from_year_month (year, DateMonth.DECEMBER);
	}


	public int compare (Month _month) {
		return integer - _month.integer;
	}


	public bool equals (Month _month) {
		return compare (_month) == 0;
	}


	public bool in_range (Month? first_month, Month? last_month) {
		return (first_month == null || this.compare (first_month) >= 0) &&
				(last_month == null || this.compare (last_month) <= 0);
	}


	public unowned string month_name () {
		const string[] names = {
			null,
			N_("January"),
			N_("February"),
			N_("March"),
			N_("April"),
			N_("May"),
			N_("June"),
			N_("July"),
			N_("August"),
			N_("September"),
			N_("October"),
			N_("November"),
			N_("December")
		};

		return dgettext (null, names[month]);
	}


	public unowned string month_short_name () {
		const string[] names = {
			null,
			N_("jan"),
			N_("feb"),
			N_("mar"),
			N_("apr"),
			N_("may"),
			N_("jun"),
			N_("jul"),
			N_("aug"),
			N_("sep"),
			N_("oct"),
			N_("nov"),
			N_("dec")
		};

		return dgettext (null, names[month]);
	}


	public string format () {
		return "%u, %s".printf (year, month_name ());
	}


	/* value adapter */
	public static bool string_to_value (ref Value v, string? s) {
		if (unlikely (s == null))
			return true;
		var p = s.split ("-");
		if (p.length < 2)
			return false;

		int64 year, month;
		if (!int64.try_parse (remove_leading_zeros (p[0]), out year))
			return false;
		if (!int64.try_parse (remove_leading_zeros (p[1]), out month))
			return false;

		v.set_instance (new Month.from_year_month ((DateYear) year, (DateMonth) month));
		return true;
	}


	public static bool value_to_string (out string? s, ref Value v) {
		var month = (Month) v.peek_pointer ();
		if (month == null)
			s = null;
		else
			s = "%04d-%02d".printf (month.year, month.month);
		return true;
	}
}


private string remove_leading_zeros (string str) {
	var len = str.length;
	int i;

	for (i = 0; i < len; i++)
		if (str[i] != '0')
			break;

	return str[i:len];
}


}
