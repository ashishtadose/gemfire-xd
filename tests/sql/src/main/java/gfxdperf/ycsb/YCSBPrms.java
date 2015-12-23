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
package gfxdperf.ycsb;

import hydra.BasePrms;

/**
 * A class used to store keys for test configuration settings.
 */
public class YCSBPrms extends BasePrms {
  
  static {
    setValues(YCSBPrms.class);
  }

//------------------------------------------------------------------------------

  /**
   * (String)
   * Trim interval name to use. Defaults to null, which means that no trim will
   * be reported to the performance framework.
   */
  public static Long trimInterval;

  public static String getTrimInterval() {
    Long key = trimInterval;
    return tasktab().stringAt(key, tab().stringAt(key, null));
  }

//------------------------------------------------------------------------------

  /**
   * (double)
   * Number of operations to do per second per client thread.  Defaults to 0
   * which disables throttling. This is the throughput per client thread.
   * The aggregate throughput for the workload is the throttled throughput per
   * client multiplied by the total number of clients.
   * <p>
   * Throttling introduces a random latency between operations to stagger them
   * across multiple clients. The maximum introduced latency is half of the
   * "operation interval", which is 1 second divided by the throttled
   * throughput. Therefore, the throttled throughput should be set such that
   * the average latency of the workload operation is less than half of the
   * "operation interval".
   * <p>
   * For example, if an operation is throttled to 5 operations per second, the
   * "operation interval" is 200 ms, so the average latency of the workload
   * operation should be less than 100 ms to achieve the expected throughput.
   * For each operation, the thread sleeps for a random time of up to 100 ms,
   * does the operation, then sleeps the remaining time to reach the 200 ms
   * "operation interval".
   * <p>
   * For expensive operations, the throttle can be set to a value less than 1.
   * For example, setting the throttle to 0.25 will attempt to do 1 operation
   * every 4 seconds. This will be effective for operations with average
   * latencies of up to 2 seconds.
   */
  public static Long throttledOpsPerSecond;

  public static double getThrottledOpsPerSecond() {
    Long key = throttledOpsPerSecond;
    return tasktab().doubleAt(key, tab().doubleAt(key, 0));
  }
}
