package com.pivotal.gemfirexd.internal.snappy;

import com.gemstone.gemfire.internal.DataSerializableFixedID;
import com.gemstone.gemfire.internal.shared.Version;
import com.pivotal.gemfirexd.internal.engine.GfxdSerializable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

/**
 * Created by kneeraj on 20/10/15.
 */
public final class LeadNodeExecutionContext implements GfxdSerializable {
  // TODO: KN what all do we need in execution context
  public LeadNodeExecutionContext() {
    
  }

  @Override
  public byte getGfxdID() {
    return LEAD_NODE_EXN_CTX;
  }

  @Override
  public int getDSFID() {
    return DataSerializableFixedID.GFXD_TYPE;
  }

  @Override
  public void toData(DataOutput out) throws IOException {

  }

  @Override
  public void fromData(DataInput in) throws IOException, ClassNotFoundException {

  }

  @Override
  public Version[] getSerializationVersions() {
    return new Version[0];
  }
}
