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

import java.util.Properties;

import com.gemstone.gemfire.cache.Cache;
import com.gemstone.gemfire.cache.CacheFactory;
import com.gemstone.gemfire.cache.DataPolicy;
import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.RegionShortcut;
import com.gemstone.gemfire.cache.client.ClientCache;
import com.gemstone.gemfire.cache.client.ClientCacheFactory;
import com.gemstone.gemfire.cache.client.ClientRegionShortcut;

import junit.framework.TestCase;

public class ConcurrentMapLocalJUnitTest extends TestCase {

  private Cache cache;

    protected void setUp() throws Exception {
      this.cache = new CacheFactory().set("mcast-port", "0").set("locators", "").create();
      super.setUp();
    }

    protected void tearDown() throws Exception {
      this.cache.close();
      super.tearDown();
    }
    
    public ConcurrentMapLocalJUnitTest(String name) {
      super(name);
    }
    
    private void cmOpsUnsupported(Region r) {
      Object key = "key";
      Object value = "value";
      try {
        r.putIfAbsent(key, value);
        fail("expected UnsupportedOperationException");
      } catch (UnsupportedOperationException expected) {
      }
      try {
        r.remove(key, value);
        fail("expected UnsupportedOperationException");
      } catch (UnsupportedOperationException expected) {
      }
      try {
        r.replace(key, value);
        fail("expected UnsupportedOperationException");
      } catch (UnsupportedOperationException expected) {
      }
      try {
        r.replace(key, value, "newValue");
        fail("expected UnsupportedOperationException");
      } catch (UnsupportedOperationException expected) {
      }
    }
    
    public void testEmptyRegion() {
      cmOpsUnsupported(this.cache.createRegionFactory(RegionShortcut.REPLICATE_PROXY).create("empty"));
    }
    public void testNormalRegion() {
      cmOpsUnsupported(this.cache.createRegionFactory(RegionShortcut.REPLICATE).setDataPolicy(DataPolicy.NORMAL).create("normal"));
    }
    public void testLocalRegion() {
      Region r = this.cache.createRegionFactory(RegionShortcut.LOCAL).create("local");
      Object key = "key";
      assertEquals(null, r.putIfAbsent(key, "value"));
      assertEquals("value", r.putIfAbsent(key, "value1"));
      assertEquals("value", r.get(key));
      assertEquals("value", r.replace(key, "value2"));
      assertEquals("value2", r.get(key));
      assertEquals(true, r.replace(key, "value2", "value3"));
      assertEquals(false, r.replace(key, "value2", "value3"));
      assertEquals(false, r.remove(key, "value2"));
      assertEquals(true, r.containsKey(key));
      assertEquals(true, r.remove(key, "value3"));
      assertEquals(false, r.containsKey(key));
    }

}
