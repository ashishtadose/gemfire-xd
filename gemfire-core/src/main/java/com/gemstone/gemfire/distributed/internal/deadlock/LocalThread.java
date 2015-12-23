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
package com.gemstone.gemfire.distributed.internal.deadlock;

import java.io.Serializable;
import java.lang.management.ThreadInfo;

import com.gemstone.gemfire.internal.concurrent.CFactory;
import com.gemstone.gemfire.internal.concurrent.LI;
/**
* This class is serializable version of the java 1.6 ThreadInfo
* class. It also holds a locality field to identify the VM
* where the thread exists.
* 
* @author dsmith
*
*/
public class LocalThread implements Serializable, ThreadReference {
  private static final long serialVersionUID = 1L;
  
  private final Serializable locality;
  private final String threadName;
  private final long threadId;
  private final String threadStack;
  
  public LocalThread(Serializable locatility, ThreadInfo info) {
    this.locality = locatility;
    this.threadName = info.getThreadName();
    this.threadStack = generateThreadStack(info);
    this.threadId = info.getThreadId();
  }
  
  private String generateThreadStack(ThreadInfo info) {
    //This is annoying, but the to string method on info sucks.
    StringBuilder result = new StringBuilder();
    result.append(info.getThreadName()).append(" ID=")
        .append(info.getThreadId()).append(" state=")
        .append(info.getThreadState());
    
    
    if(CFactory.getLockInfo(info) != null) {
      result.append("\n\twaiting to lock <" + CFactory.getLockInfo(info) + ">");
    }
    for(StackTraceElement element : info.getStackTrace()) {
      result.append("\n\tat " + element);
      for(LI monitor: CFactory.getLockedMonitors(info)) {
        if(element.equals(monitor.getLockedStackFrame())) {
          result.append("\n\tlocked <" + monitor + ">");
        }
      }
    }
    
    if(CFactory.getLockedSynchronizers(info).length > 0) {
      result.append("\nLocked synchronizers:");
      for(LI sync : CFactory.getLockedSynchronizers(info)) {
        result.append("\n" + sync.getClassName() + "@" + sync.getIdentityHashCode());
        
      }
    }
    
    return result.toString();
  }
  public Serializable getLocatility() {
    return locality;
  }
  public String getThreadName() {
    return threadName;
  }
  public long getThreadId() {
    return threadId;
  }
  public String getThreadStack() {
    return threadStack;
  }
  @Override
  public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + (int)(threadId ^ (threadId >>> 32));;
    result = prime * result
        + ((locality == null) ? 0 : locality.hashCode());
    return result;
  }
  @Override
  public boolean equals(Object obj) {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (!(obj instanceof LocalThread))
      return false;
    LocalThread other = (LocalThread) obj;
    if (threadId != other.threadId)
      return false;
    if (locality == null) {
      if (other.locality != null)
        return false;
    } else if (!locality.equals(other.locality))
      return false;
    return true;
  }
  
  @Override
  public String toString() {
    return locality + ":" + threadName; 
  }
}