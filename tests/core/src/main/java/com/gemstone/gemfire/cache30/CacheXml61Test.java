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
package com.gemstone.gemfire.cache30;

import java.util.Properties;

import com.gemstone.gemfire.DataSerializable;
import com.gemstone.gemfire.DataSerializer;
import com.gemstone.gemfire.cache.Cache;
import com.gemstone.gemfire.cache.CacheException;
import com.gemstone.gemfire.cache.PartitionAttributes;
import com.gemstone.gemfire.cache.PartitionAttributesFactory;
import com.gemstone.gemfire.cache.PartitionResolver;
import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.RegionAttributes;
import com.gemstone.gemfire.cache.Scope;
import com.gemstone.gemfire.cache.client.Pool;
import com.gemstone.gemfire.cache.client.PoolFactory;
import com.gemstone.gemfire.cache.client.PoolManager;
import com.gemstone.gemfire.internal.InternalDataSerializer;
import com.gemstone.gemfire.internal.InternalInstantiator;
import com.gemstone.gemfire.internal.cache.GemFireCacheImpl;
import com.gemstone.gemfire.internal.cache.xmlcache.CacheCreation;
import com.gemstone.gemfire.internal.cache.xmlcache.CacheXml;
import com.gemstone.gemfire.internal.cache.xmlcache.RegionAttributesCreation;
import com.gemstone.gemfire.internal.cache.xmlcache.ResourceManagerCreation;
import com.gemstone.gemfire.internal.cache.xmlcache.SerializerCreation;

import dunit.DistributedTestCase;
import dunit.Host;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.io.Serializable;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;

/**
 * Tests 6.1 cache.xml features.
 * 
 * @author aingle, skumar
 * @since 6.1
 */

public class CacheXml61Test extends CacheXml60Test {
  
  // ////// Constructors

  public CacheXml61Test(String name) {
    super(name);
  }

  // ////// Helper methods

  protected String getGemFireVersion()
  {
    return CacheXml.VERSION_6_1;
  }


  /**
   * Tests that a region created with a named attributes set programmatically
   * for delta propogation has the correct attributes.
   * 
   */
  public void testRegionAttributesForRegionEntryCloning() throws CacheException
  {
    final String rNameBase = getUniqueName();
    final String r1 = rNameBase + "1";

    // Setting multi-cast via nested region attributes
    CacheCreation creation = new CacheCreation();
    RegionAttributesCreation attrs = new RegionAttributesCreation(creation);
    attrs.setScope(Scope.LOCAL);
    attrs.setEarlyAck(false);
    attrs.setCloningEnable(false);
    attrs.setMulticastEnabled(true);
    creation.createRegion(r1, attrs);
    
    testXml(creation);

    Cache c = getCache();
    assertTrue(c instanceof GemFireCacheImpl);
    c.loadCacheXml(generate(creation));

    Region reg1 = c.getRegion(r1);
    assertNotNull(reg1);
    assertEquals(Scope.LOCAL, reg1.getAttributes().getScope());
    assertFalse(reg1.getAttributes().getEarlyAck());
    assertTrue(reg1.getAttributes().getMulticastEnabled());
    assertFalse(reg1.getAttributes().getCloningEnabled());
    
    //  changing Clonned setting
    reg1.getAttributesMutator().setCloningEnabled(true);
    assertTrue(reg1.getAttributes().getCloningEnabled());

    reg1.getAttributesMutator().setCloningEnabled(false);
    assertFalse(reg1.getAttributes().getCloningEnabled());
    
    // for sub region - a child attribute should be inherited
    String sub = "subRegion";
    RegionAttributesCreation attrsSub = new RegionAttributesCreation(creation);
    attrsSub.setScope(Scope.LOCAL);
    reg1.createSubregion(sub, attrsSub);
    Region subRegion = reg1.getSubregion(sub);
    assertFalse(subRegion.getAttributes().getCloningEnabled());
    subRegion.getAttributesMutator().setCloningEnabled(true);
    assertTrue(subRegion.getAttributes().getCloningEnabled());
  }
}
