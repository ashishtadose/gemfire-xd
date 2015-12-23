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

package com.gemstone.gemfire.cache.util;

/**
 * Abstract class for CqListener. 
 * Utility class that implements all methods in <code>CqListener</code>
 * with empty implementations. Applications can subclass this class and only
 * override the methods of interest.
 *
 * @author anil 
 * @since 5.1
 */

import com.gemstone.gemfire.cache.query.CqListener;
import com.gemstone.gemfire.cache.query.CqEvent;

public abstract class CqListenerAdapter implements CqListener {
  
  /**
   * An event occurred that modifies the results of the query.
   * This event does not contain an error.
   */
  public void onEvent(CqEvent aCqEvent) {
  }

  /** 
   * An error occurred in the processing of a CQ.
   * This event does contain an error. The newValue and oldValue in the
   * event may or may not be available, and will be null if not available.
   */
  public void onError(CqEvent aCqEvent) {
  }
  
  /**
  * Called when the CQ is closed, the base region is destroyed, when
  * the cache is closed, or when this listener is removed from a CqQuery
  * using a <code>CqAttributesMutator</code>.
  *
  * <p>Implementations should cleanup any external
  * resources such as database connections. Any runtime exceptions this method
  * throws will be logged.
  *
  * <p>It is possible for this method to be called multiple times on a single
  * callback instance, so implementations must be tolerant of this.
  *
  * @see com.gemstone.gemfire.cache.CacheCallback#close
  */
  public void close() {
  }
}
