namespace Db {


public class MysqlDatabase : Database {
	private Mysql.Database native;


	protected override Type statement_type () {
		return typeof (MysqlStatement);
	}


	public override int last_insert_id () {
		return (int) this.native.insert_id ();
	}
}


}

