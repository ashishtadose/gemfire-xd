package com.pivotal.gemfirexd.internal.catalog;

/**
 * Need to keep GemXD independent of any snappy/spark/hive related 
 * classes. An implementation of this can be made which adheres to this 
 * interface and can be instantiated when the snappy embedded cluster
 * initializes and set into the GemFireStore instance.
 * 
 * @author kneeraj
 *
 */
public interface ExternalCatalog {

	/**
	 * Will be used by the execution engine to route to JobServer
	 * when it finds out that this table is a column table.
	 * 
	 * @param tableName
	 * @return true if the table is column table, false if row/ref table
	 */
	boolean isColumnTable(String tableName, boolean skipLocks);

	/**
	 * Will be used by the execution engine to execute query in gemfirexd
	 * if tablename is of a row table.
	 *
	 * @param tableName
	 * @return true if the table is column table, false if row/ref table
	 */
	boolean isRowTable(String tableName, boolean skipLocks);

	void stop();
}
