package com.gemstone.gemfire.internal.snappy;

import java.util.Set;
import java.util.UUID;

import com.gemstone.gemfire.internal.cache.BucketRegion;

public abstract class CallbackFactoryProvider {

  // no-op implementation.
  private static StoreCallbacks storeCallbacks = new StoreCallbacks() {

    @Override
    public Set createCachedBatch(BucketRegion region, UUID batchID, int bucketID) {
      return null;
    }
  };

  public static void setStoreCallbacks(StoreCallbacks cb) {
    storeCallbacks = cb;
  }

  public static StoreCallbacks getStoreCallbacks() {
    return storeCallbacks;
  }

}