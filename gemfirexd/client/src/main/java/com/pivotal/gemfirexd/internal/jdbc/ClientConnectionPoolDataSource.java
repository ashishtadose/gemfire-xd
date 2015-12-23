/*

   Derby - Class com.pivotal.gemfirexd.internal.jdbc.ClientConnectionPoolDataSource

   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

*/

/*
 * Changes for GemFireXD distributed data platform (some marked by "GemStone changes")
 *
 * Portions Copyright (c) 2010-2015 Pivotal Software, Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License. You
 * may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License. See accompanying
 * LICENSE file.
 */

package com.pivotal.gemfirexd.internal.jdbc;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.sql.SQLException;
import javax.sql.ConnectionPoolDataSource;
import javax.sql.PooledConnection;

import com.pivotal.gemfirexd.internal.client.am.LogWriter;
import com.pivotal.gemfirexd.internal.client.am.SqlException;
import com.pivotal.gemfirexd.internal.shared.common.i18n.MessageUtil;
import com.pivotal.gemfirexd.internal.shared.common.reference.MessageId;
import com.pivotal.gemfirexd.jdbc.ClientDRDADriver;

/**
 * ClientConnectionPoolDataSource is a factory for PooledConnection objects.
 * An object that implements this interface
 * will typically be registered with a naming service that is based on the
 * Java Naming and Directory Interface (JNDI). Use
 * ClientConnectionPoolDataSource if your application runs under
 * JDBC3.0 or JDBC2.0, that is, on the following Java Virtual Machines:
 * <p/>
 * <UL>
 * <LI> JDBC 3.0 - Java 2 - JDK 1.4, J2SE 5.0
 * <LI> JDBC 2.0 - Java 2 - JDK 1.2,1.3
 * </UL>
 */
public class ClientConnectionPoolDataSource extends ClientDataSource 
                                           implements ConnectionPoolDataSource {
    private static final long serialVersionUID = -539234282156481377L;
    /** Message utility used to obtain localized messages. */
    private static final MessageUtil msgUtil =
            new MessageUtil("com.pivotal.gemfirexd.internal.loc.clientmessages");
    public static final String className__ = "com.pivotal.gemfirexd.internal.jdbc.ClientConnectionPoolDataSource";

    /**
     * Specifies the maximum number of statements that can be cached per
     * connection by the JDBC driver.
     * <p>
     * A value of <code>0</code> disables statement caching, negative values
     * are not allowed. The default is that caching is disabled.
     *
     * @serial
     */
    private int maxStatements = 0;

    public ClientConnectionPoolDataSource() {
        super();
    }

    // ---------------------------interface methods-------------------------------

    // Attempt to establish a physical database connection that can be used as a pooled connection.
    public PooledConnection getPooledConnection() throws SQLException {
        try
        {
            LogWriter dncLogWriter = super.computeDncLogWriterForNewConnection("_cpds");
            if (dncLogWriter != null) {
                dncLogWriter.traceEntry(this, "getPooledConnection");
            }
            PooledConnection pooledConnection = getPooledConnectionX(dncLogWriter, this, getUser(), getPassword());
            if (dncLogWriter != null) {
                dncLogWriter.traceExit(this, "getPooledConnection", pooledConnection);
            }
            return pooledConnection;
        }
        catch ( SqlException se )
        {
            throw se.getSQLException(null /* GemStoneAddition */);
        }
    }

    // Standard method that establishes the initial physical connection using CPDS properties.
    public PooledConnection getPooledConnection(String user, String password) throws SQLException {
        try
        {
            LogWriter dncLogWriter = super.computeDncLogWriterForNewConnection("_cpds");
            if (dncLogWriter != null) {
                dncLogWriter.traceEntry(this, "getPooledConnection", user, "<escaped>");
            }
            PooledConnection pooledConnection = getPooledConnectionX(dncLogWriter, this, user, password);
            if (dncLogWriter != null) {
                dncLogWriter.traceExit(this, "getPooledConnection", pooledConnection);
            }
            return pooledConnection;
        }
        catch ( SqlException se )
        {
            throw se.getSQLException(null /* GemStoneAddition */);
        }
    }

    //  method that establishes the initial physical connection
    // using DS properties instead of CPDS properties.
    private PooledConnection getPooledConnectionX(LogWriter dncLogWriter, 
                        ClientBaseDataSource ds, String user, 
                        String password) throws SQLException {
            return ClientDRDADriver.getFactory().newClientPooledConnection(ds,
                    dncLogWriter, user, password);
    }   

    /**
     * Specifies the maximum size of the statement cache.
     *
     * @param maxStatements maximum number of cached statements
     *
     * @throws IllegalArgumentException if <code>maxStatements</code> is
     *      negative
     */
    public void setMaxStatements(int maxStatements) {
        // Disallow negative values.
        if (maxStatements < 0) {
            throw new IllegalArgumentException(msgUtil.getTextMessage(
                    MessageId.CONN_NEGATIVE_MAXSTATEMENTS,
                    new Integer(maxStatements)));
        }
        this.maxStatements = maxStatements;
    }

    /**
     * Returns the maximum number of JDBC prepared statements a connection is
     * allowed to cache.
     *
     * @return Maximum number of statements to cache, or <code>0</code> if
     *      caching is disabled (default).
     */
    public int getMaxStatements() {
        return this.maxStatements;
    }

    /**
     * Internally used method.
     *
     * @see ClientBaseDataSource#maxStatementsToPool
     */
    public int maxStatementsToPool() {
        return this.maxStatements;
    }

    /**
     * Make sure the state of the de-serialized object is valid.
     */
    private final void validateState() {
        // Make sure maxStatements is zero or higher.
        if (maxStatements < 0) {
            throw new IllegalArgumentException(msgUtil.getTextMessage(
                    MessageId.CONN_NEGATIVE_MAXSTATEMENTS,
                    new Integer(maxStatements)));
        }
    }

    /**
     * Read an object from the ObjectInputStream.
     * <p>
     * This implementation differs from the default one by initiating state
     * validation of the object created.
     *
     * @param inputStream data stream to read objects from
     * @throws ClassNotFoundException if instantiating a class fails
     * @throws IOException if reading from the stream fails
     */
    private void readObject(ObjectInputStream inputStream)
            throws ClassNotFoundException, IOException {
     // Always perform the default de-serialization first
     inputStream.defaultReadObject();

     // Ensure that object state has not been corrupted or tampered with.
     validateState();
  }
}
