package com.pivotal.gemfirexd.internal.snappy;

import java.io.DataOutput;

import com.pivotal.gemfirexd.internal.engine.distributed.SnappyResultHolder;
import com.pivotal.gemfirexd.internal.engine.distributed.message.LeadNodeExecutorMsg;

/**
 * Created by kneeraj on 20/10/15.
 */
public interface SparkSQLExecute {

  /**
   * This is invoked by the LeadNode execute to pack the results in the HeapDataOutputStream
   */
  void packRows(LeadNodeExecutorMsg msg, SnappyResultHolder snappyResultHolder);

  /**
   * Called at the lowest level to serialize the SnappyResultHolder object per batch.
   * @param out
   */
  void serializeRows(DataOutput out);
}
