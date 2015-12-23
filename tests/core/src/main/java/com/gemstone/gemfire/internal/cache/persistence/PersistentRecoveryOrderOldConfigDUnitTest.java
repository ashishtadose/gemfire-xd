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
package com.gemstone.gemfire.internal.cache.persistence;

import java.io.File;

import com.gemstone.gemfire.cache.Cache;
import com.gemstone.gemfire.cache.DataPolicy;
import com.gemstone.gemfire.cache.DiskStore;
import com.gemstone.gemfire.cache.DiskStoreFactory;
import com.gemstone.gemfire.cache.DiskWriteAttributesFactory;
import com.gemstone.gemfire.cache.RegionFactory;
import com.gemstone.gemfire.cache.Scope;

import dunit.AsyncInvocation;
import dunit.SerializableRunnable;
import dunit.VM;

/**
 * @author dsmith
 *
 */
public class PersistentRecoveryOrderOldConfigDUnitTest extends
    PersistentRecoveryOrderDUnitTest {

  public PersistentRecoveryOrderOldConfigDUnitTest(String name) {
    super(name);
    // TODO Auto-generated constructor stub
  }
  
  @Override
  protected AsyncInvocation createPersistentRegionAsync(final VM vm) {
    SerializableRunnable createRegion = new SerializableRunnable("Create persistent region") {
      public void run() {
        Cache cache = getCache();
        File dir = getDiskDirForVM(vm);
        dir.mkdirs();
        RegionFactory rf = new RegionFactory();
//        rf.setDiskSynchronous(true);
        rf.setDataPolicy(DataPolicy.PERSISTENT_REPLICATE);
        rf.setScope(Scope.DISTRIBUTED_ACK);
        rf.setDiskDirs(new File[] {dir});
        DiskWriteAttributesFactory dwf = new DiskWriteAttributesFactory();
        dwf.setMaxOplogSize(1);
        dwf.setSynchronous(true);
        rf.setDiskWriteAttributes(dwf.create());
        rf.create(REGION_NAME);
      } 
    };
    return vm.invokeAsync(createRegion);
  }

}
