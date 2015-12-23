/*
 * Copyright (c) 2010-2015 Pivotal Software, Inc. All rights reserved.
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
package sql.sqlutil;

import hydra.Log;
import hydra.MasterController;
import hydra.gemfirexd.NetworkServerHelper;
import hydra.gemfirexd.NetworkServerHelper.Endpoint;

import java.sql.Connection;
import java.sql.SQLException;

import java.util.Iterator;
import java.util.Map;
import java.util.Properties;

import sql.GFEDBClientManager;
import sql.GFEDBManager.Isolation;
import util.TestException;
import util.TestHelper;

import org.apache.commons.dbcp.BasicDataSource;

import com.pivotal.gemfirexd.jdbc.ClientAttribute;

public class PooledConnectionDBCP extends GFEDBClientManager {
  private volatile static BasicDataSource ds;
  private volatile static boolean dsSet = false;
  private static Properties connProp = new Properties();
  private static Integer lock = 1;
  
  public static Connection getConnection() throws SQLException {
    if (ds == null) {
      synchronized (lock) {        
        getDataSource(Isolation.NONE);        
      }
    }
    
    while(!dsSet) {
      Log.getLogWriter().info("waiting ds to be set");
      MasterController.sleepForMs(1000);
    }
    
    return ds.getConnection();
  }
  
  public static Connection getRCConnection() throws SQLException {
    if (ds == null) {
      synchronized (lock) {
        getDataSource(Isolation.READ_COMMITTED);
      }
    }
    
    while(!dsSet) {
      Log.getLogWriter().info("waiting ds to be set");
      MasterController.sleepForMs(1000);
    }
    
    return ds.getConnection();
  }
  
  public static Connection getRRConnection() throws SQLException {
    if (ds == null) {
      synchronized (lock) {
        getDataSource(Isolation.REPEATABLE_READ);
      }
    }
    
    while(!dsSet) {
      Log.getLogWriter().info("waiting ds to be set");
      MasterController.sleepForMs(1000);
    }
    
    return ds.getConnection();
  } 
  
  public static Connection getRCConnection(Properties p) throws SQLException {
    if (ds == null) {
      synchronized (lock) {
        connProp.putAll(p);
        getDataSource(Isolation.READ_COMMITTED);
      }
    }
    
    while(!dsSet) {
      Log.getLogWriter().info("waiting ds to be set");
      MasterController.sleepForMs(1000);
    }
    
    return ds.getConnection();
  }
  
  public static Connection getRRConnection(Properties p) throws SQLException {
    if (ds == null) {
      synchronized (lock) {
        connProp.putAll(p);
        getDataSource(Isolation.REPEATABLE_READ);
      }
    }
    
    while(!dsSet) {
      Log.getLogWriter().info("waiting ds to be set");
      MasterController.sleepForMs(1000);
    }
    
    return ds.getConnection();
  } 
  
  
  public static BasicDataSource getDataSource(Isolation isolation) {
    if (ds == null) {
      setupDataSource(isolation);
      Log.getLogWriter().info("max active is " + ds.getMaxActive());
    }

    return ds;
  }
  
  @SuppressWarnings("unchecked")
  private static void setupDataSource(Isolation isolation) {
    ds = new BasicDataSource();
    Endpoint locatorEndPoint = (Endpoint) (NetworkServerHelper.getNetworkLocatorEndpoints()).get(0);
    String hostname = getHostNameFromEndpoint(locatorEndPoint);
    int port = getPortFromEndpoint(locatorEndPoint); 
    
    connProp.putAll(getExtraConnProp());
    
    try {
      ds.setDriverClassName(driver);
      ds.setUrl(protocol + hostname+ ":" + port);
      
      ds.setMaxActive(100);
      
      if (isolation == Isolation.NONE) {
      } else if (isolation == Isolation.READ_COMMITTED) {
        ds.setDefaultTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
        ds.setDefaultAutoCommit(false);
      } else {
        ds.setDefaultTransactionIsolation(Connection.TRANSACTION_REPEATABLE_READ);
        ds.setDefaultAutoCommit(false);
      }
      
      StringBuilder sb = new StringBuilder();
      
      for (Iterator<?> iter = connProp.entrySet().iterator(); iter.hasNext(); ) {
        Map.Entry<String, String> entry = (Map.Entry<String, String>) iter.next();
        ds.addConnectionProperty(entry.getKey(), entry.getValue()); //add additional conn prop
        
        sb.append(entry.getKey() + " is set to " + entry.getValue() +"\n");
      }
           
      dsSet = true;
      Log.getLogWriter().info("basic source url is set as " + ds.getUrl());
      Log.getLogWriter().info("basic data source setting the following connection prop: " + sb.toString());
      
    } catch (Exception e) {
      throw new TestException("could not set data source" + TestHelper.getStackTrace(e));
    }
  }
  
  

}
