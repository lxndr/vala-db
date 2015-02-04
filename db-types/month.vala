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


namespace Kv {


public class Month {
	public int raw_value { get; set; }


	public DateYear year {
		get { return (DateYear) (raw_value / 12); }
	}


	public DateMonth month {
		get { return (DateMonth) (raw_value % 12 + 1); }
	}


	public Date? first_day {
		owned get {
			if (unlikely (raw_value == 0))
				return null;
			else
				return new Date.from_ymd (year, month, 1);
		}
	}


	public Date? last_day {
		owned get {
			if (unlikely (raw_value == 0))
				return null;
			var m = month;
			return new Date.from_ymd (year, m, m.get_days_in_month (year));
		}
	}


	public Month.from_raw_value (int _value) {
		raw_value = _value;
	}


	public Month.from_year_month (DateYear _year, DateMonth _month) {
		raw_value = (int) _year * 12 + (int) _month - 1;
	}


	public Month.now () {
		var date = new DateTime.now_local ();
		raw_value = (int) date.get_year () * 12 + (int) date.get_month () - 1;
	}


	public unowned Month assign (Month that) {
		raw_value = that.raw_value;
		return this;
	}


	public void prev () {
		raw_value -= 1;
	}


	public void next () {
		raw_value += 1;
	}


	public Month get_prev () {
		return new Month.from_raw_value (raw_value - 1);
	}


	public Month get_next () {
		return new Month.from_raw_value (raw_value + 1);
	}


	public Month get_first_month () {
		return new Month.from_year_month (year, DateMonth.JANUARY);
	}


	public Month get_last_month () {
		return new Month.from_year_month (year, DateMonth.DECEMBER);
	}


	public int compare (Month _month) {
		return raw_value - _month.raw_value;
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
		return "%s %u".printf (month_name (), year);
	}
}


}
