package com.pivotal.gemfirexd.internal.snappy;

import com.gemstone.gemfire.internal.shared.Version;
import com.gemstone.gemfire.distributed.internal.membership.InternalDistributedMember;

import java.util.HashSet;

/**
 * This class should be used to hold the callback factories that are used to communicate
 * with Snappy.
 * The callbacks need to be set when snappy is initializing
 * <p/>
 * Created by hemantb.
 */
public abstract class CallbackFactoryProvider {
  // no-op implementation.
  private static ClusterCallbacks clusterCallbacks = new ClusterCallbacks() {

    public HashSet<String> getLeaderGroup() {
      return null;
    }

    public void launchExecutor(String driver_url, InternalDistributedMember driverDM) {
    }

    public String getDriverURL() {
      return null;
    }

    public void stopExecutor() {
    }

    @Override
    public SparkSQLExecute getSQLExecute(String sql, LeadNodeExecutionContext ctx, Version v) {
       return null;
    }
  };

  public static ClusterCallbacks getClusterCallbacks() {
    return clusterCallbacks;
  }

  public static void setClusterCallbacks(ClusterCallbacks cb) {
    clusterCallbacks = cb;
  }
}
