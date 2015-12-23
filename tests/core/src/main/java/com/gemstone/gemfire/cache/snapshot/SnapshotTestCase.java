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
package com.gemstone.gemfire.cache.snapshot;

import java.io.File;
import java.io.FilenameFilter;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import junit.framework.TestCase;

import com.examples.snapshot.MyObject;
import com.gemstone.gemfire.cache.Cache;
import com.gemstone.gemfire.cache.CacheFactory;
import com.gemstone.gemfire.cache.DiskStore;
import com.gemstone.gemfire.cache.snapshot.RegionGenerator.SerializationType;

public class SnapshotTestCase extends TestCase {
  protected File store;
  protected File snaps;
  protected Cache cache;
  protected RegionGenerator rgen;
  protected DiskStore ds;

  public void setUp() throws Exception {
    store = new File("store-" + Math.abs(new Random().nextInt()));
    store.mkdir();
    
    snaps = new File("snapshots-" + Math.abs(new Random().nextInt()));
    snaps.mkdir();

    rgen = new RegionGenerator();

    CacheFactory cf = new CacheFactory()
      .set("mcast-port", "0")
      .set("log-level", "error");
    cache = cf.create();
    
    ds = cache.createDiskStoreFactory()
        .setMaxOplogSize(1)
        .setDiskDirs(new File[] { store })
        .create("snapshotTest");
  }
  
  public void tearDown() throws Exception {
    cache.close();
    deleteFiles(store);
    deleteFiles(snaps);
  }
  
  public Map<Integer, MyObject> createExpected(SerializationType type) {
    Map<Integer, MyObject> expected = new HashMap<Integer, MyObject>();
    for (int i = 0; i < 1000; i++) {
      expected.put(i, rgen.createData(type, i, "The number is " + i));
    }
    return expected;
  }

  public static void deleteFiles(File dir) {
    File[] deletes = dir.listFiles(new FilenameFilter() {
      @Override
      public boolean accept(File dir, String name) {
        return true;
      }
    });
    
    if (deletes != null) {
      for (File f : deletes) {
        f.delete();
      }
    }
    dir.delete();
  }
}
