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
package com.gemstone.gemfire.internal.cache;

import java.io.File;
import java.util.Properties;

import junit.framework.TestCase;

import com.gemstone.gemfire.cache.AttributesFactory;
import com.gemstone.gemfire.cache.Cache;
import com.gemstone.gemfire.cache.CacheFactory;
import com.gemstone.gemfire.cache.DataPolicy;
import com.gemstone.gemfire.cache.DiskStore;
import com.gemstone.gemfire.cache.DiskStoreFactory;
import com.gemstone.gemfire.cache.EvictionAction;
import com.gemstone.gemfire.cache.EvictionAttributes;
import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.RegionAttributes;
import com.gemstone.gemfire.cache.Scope;
import com.gemstone.gemfire.distributed.DistributedSystem;
import com.gemstone.gemfire.internal.Assert;
import com.gemstone.gemfire.internal.cache.lru.EnableLRU;
import com.gemstone.gemfire.internal.cache.lru.LRUClockNode;
import com.gemstone.gemfire.internal.cache.lru.NewLRUClockHand;

/**
 * Test for simluating the deadLock condition as in bug#37244
 * 
 * @author pbatra
 * 
 */
public class Bug37244JUnitTest extends TestCase
{

  private static Cache cache = null;

  private static DistributedSystem distributedSystem = null;

  protected static String regionName = "TestRegion";

  /*
   * constructor
   */
  public Bug37244JUnitTest(String name) {
    super(name);
  }

  public void setUp() throws Exception
  {
    super.setUp();
  }

  public void tearDown() throws Exception
  {

    super.tearDown();
  }

  /**
   * Method for intializing the VM
   * 
   * @return
   * @throws Exception
   */
  private static void initializeVM() throws Exception
  {
    Properties props = new Properties();
    props.setProperty("mcast-port", "0");
    props.setProperty("locators", "");
    props.setProperty("log-level", "info"); // to keep diskPerf logs smaller
    distributedSystem = DistributedSystem.connect(props);
    cache = CacheFactory.create(distributedSystem);
    assertNotNull(cache);
    DiskStoreFactory dsf = cache.createDiskStoreFactory();
    AttributesFactory factory = new AttributesFactory();
    factory.setScope(Scope.DISTRIBUTED_ACK);

    File dir = new File("testingDirectoryDefault");
    dir.mkdir();
    dir.deleteOnExit();
    File[] dirs = { dir };
    dsf.setDiskDirsAndSizes(dirs, new int[] { Integer.MAX_VALUE });

    dsf.setAutoCompact(false);
    DirectoryHolder.SET_DIRECTORY_SIZE_IN_BYTES_FOR_TESTING_PURPOSES = true;
    try {
      factory.setDiskStoreName(dsf.create(regionName).getName());
    } finally {
      DirectoryHolder.SET_DIRECTORY_SIZE_IN_BYTES_FOR_TESTING_PURPOSES = false;
    }
    factory.setDiskSynchronous(true);
    factory.setDataPolicy(DataPolicy.PERSISTENT_REPLICATE);

    factory.setEvictionAttributes(EvictionAttributes.createLRUEntryAttributes(
        1, EvictionAction.OVERFLOW_TO_DISK));
    RegionAttributes attr = factory.create();
    DistributedRegion distRegion = new DistributedRegion(regionName, attr,
        null, (GemFireCacheImpl)cache, new InternalRegionArguments()
            .setDestroyLockFlag(true).setRecreateFlag(false)
            .setSnapshotInputStream(null).setImageTarget(null));
    assertNotNull(distRegion);
    ((AbstractLRURegionMap)distRegion.entries)
        ._setLruList((new TestLRUClockHand(distRegion,
            ((AbstractLRURegionMap)distRegion.entries)._getCCHelper())));
    ((GemFireCacheImpl)cache).createVMRegion(regionName, attr,
        new InternalRegionArguments().setInternalMetaRegion(distRegion)
            .setDestroyLockFlag(true).setSnapshotInputStream(null)
            .setImageTarget(null));

  }

  public void testPutWhileclear()
  {
    try {
      initializeVM();

      assertNotNull(cache);
      Region rgn = cache.getRegion(regionName);
      assertNotNull(rgn);

      //put two entries into the region 
      for (int i = 0; i < 2; i++) {
        rgn.put(new Long(i), new Long(i));
      }

      //get an entry back 
      Long value = (Long)rgn.get(new Long(0));

      //check for entry value
      assertTrue("Test failed ", value.equals(new Long(0)));

    }
    catch (Exception ex) {
      ex.printStackTrace();
      fail("Test failed");

    }
    finally {
      assertNotNull(cache);
      Region rgn = cache.getRegion(regionName);
      assertNotNull(rgn);
      rgn.localDestroyRegion();
      cache.close();

    }

  }

  /**
   * Test Implementation class of NewLRUClockHand for bug37244.
   * 
   * 
   * @author pbatra
   * @author pallavis
   * 
   */

  static public class TestLRUClockHand extends NewLRUClockHand
  {

    protected static Object mutex = new Object();

//    private String regionName = "TestRegion";

    protected static boolean EXECUTE_AFTER_GET_CALL = false;

    /**
     * Constructor
     * 
     * @param region
     * @param ccHelper
     */
    public TestLRUClockHand(Region region, EnableLRU ccHelper) {
      super(region, ccHelper,new InternalRegionArguments());

    }

    /**
     * Overridden getLRUEntry method
     */
    public LRUClockNode getLRUEntry()
    {
      if (EXECUTE_AFTER_GET_CALL) {
        Cache cache = CacheFactory.getAnyInstance();
        Assert.assertTrue(cache != null);
        LocalRegion region = (LocalRegion)cache.getRegion(regionName);
        Assert.assertTrue(region != null);
        Thread clearThread = new Thread(new clearThread(region));
        clearThread.start();
        try {
          synchronized (mutex) {
            mutex.wait(10000);
          }
        }
        catch (InterruptedException ie) {
          if (cache.getLogger().fineEnabled()) {
            cache.getLogger().fine(
                "TestLRUClockHand#getLRUEntry Got an interrupted Exception");
          }
          fail("interrupted");
        }
      }

      LRUClockNode aNode = super.getLRUEntry();
      return aNode;
    }

    /**
     * 
     * clearThread
     * 
     */
    protected static class clearThread implements Runnable
    {
      LocalRegion region = null;

      clearThread(LocalRegion rgn) {
        super();
        this.region = rgn;

      }

      public void run()
      {
        Cache cache = CacheFactory.getAnyInstance();
        region.getDiskRegion().acquireWriteLock();
        try {
          Thread putThread = new Thread(new putThread(region));
          putThread.start();
          Thread.sleep(2000);
          synchronized (mutex) {
            mutex.notify();
          }
          Thread.sleep(5000);

          region.clear();
        }
        catch (InterruptedException e) {
          if (cache.getLogger().fineEnabled()) {
            cache.getLogger().fine(
                "TestLRUClockHand#clearThread Got an interrupted Exception");
          }
          fail("interrupted");
        }
        catch (Exception ie) {
          fail("TestLRUClockHand#clearThread Got an Exception");
        }
        finally {
          region.getDiskRegion().releaseWriteLock();
        }

      }
    }

    /**
     * 
     * putThread
     * 
     */

    protected static class putThread implements Runnable
    {
      LocalRegion region = null;

      putThread(LocalRegion rgn) {
        super();
        this.region = rgn;

      }

      public void run()
      {
        region.put(new Long(1), "2");

      }
    }
  }
}
