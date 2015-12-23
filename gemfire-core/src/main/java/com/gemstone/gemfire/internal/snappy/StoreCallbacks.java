package com.gemstone.gemfire.internal.snappy;

import java.util.Set;
import java.util.UUID;

import com.gemstone.gemfire.internal.cache.BucketRegion;

/**
 * Created by skumar on 6/11/15.
 */
public interface StoreCallbacks {
  Set createCachedBatch(BucketRegion region, UUID batchID, int bucketID);
}