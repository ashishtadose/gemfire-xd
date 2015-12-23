package com.pivotal.gemfirexd.internal.snappy;

import com.gemstone.gemfire.internal.shared.Version;
import com.gemstone.gemfire.distributed.internal.membership.InternalDistributedMember;

import java.util.HashSet;

/**
 * Callbacks that are required for cluster management of Snappy should go here.
 *
 * Created by hemantb on 10/12/15.
 *
 */
public interface ClusterCallbacks {

    public HashSet<String> getLeaderGroup();

    public void launchExecutor(String driver_url, InternalDistributedMember driverDM);

    public String getDriverURL();

    public void stopExecutor();

    public SparkSQLExecute getSQLExecute(String sql, LeadNodeExecutionContext ctx, Version v);

}
