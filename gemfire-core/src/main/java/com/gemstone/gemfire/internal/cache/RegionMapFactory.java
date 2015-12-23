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



/**
 * Used to produce instances of RegionMap
 *
 * @since 3.5.1
 *
 * @author Darrel Schneider
 *
 */
class RegionMapFactory {
  /**
   * Creates a RegionMap that is stored in the VM.
   * @param owner the region that will be the owner of the map
   * @param attrs attributes used to create the map and its entries
   */
  public static RegionMap createVM(LocalRegion owner,
                                   RegionMap.Attributes attrs,InternalRegionArguments internalRegionArgs)
  {
    //final boolean isNotPartitionedRegion = !(owner.getPartitionAttributes() != null || owner
    //.getDataPolicy().withPartitioning());
    if (owner.isProxy() /*|| owner instanceof PartitionedRegion*/) { // TODO enabling this causes eviction tests to fail
      return new ProxyRegionMap(owner, attrs, internalRegionArgs);
    } else if (internalRegionArgs.isReadWriteHDFSRegion()) {
      if (owner.getEvictionController() == null) {
        return new HDFSRegionMapImpl(owner, attrs, internalRegionArgs);
      }
      return new HDFSLRURegionMap(owner, attrs, internalRegionArgs);
    //else if (owner.getEvictionController() != null && isNotPartitionedRegion) {
    } else if (owner.getEvictionController() != null ) {
      return new VMLRURegionMap(owner, attrs,internalRegionArgs);
    } else {
      return new VMRegionMap(owner, attrs, internalRegionArgs);
    }
  }

  /**
   * Creates a RegionMap that is stored in the VM.
   * Called during DiskStore recovery before the region actually exists.
   * @param owner the place holder disk region that will be the owner of the map
   *      until the actual region is created.
   */
  public static RegionMap createVM(PlaceHolderDiskRegion owner,
      DiskStoreImpl ds, InternalRegionArguments internalRegionArgs) {
    RegionMap.Attributes ma = new RegionMap.Attributes();
    ma.statisticsEnabled = owner.getStatisticsEnabled();
    ma.loadFactor = owner.getLoadFactor();
    ma.initialCapacity = owner.getInitialCapacity();
    ma.concurrencyLevel = owner.getConcurrencyLevel();
    if (owner.getLruAlgorithm() != 0) {
      return new VMLRURegionMap(owner, ma, internalRegionArgs);
    }
    else {
      return new VMRegionMap(owner, ma, internalRegionArgs);
    }
  }
}
