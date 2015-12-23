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
package com.gemstone.gemfire.internal.cache.partitioned;

import com.gemstone.gemfire.i18n.LogWriterI18n;
import com.gemstone.gemfire.internal.i18n.LocalizedStrings;
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.util.Iterator;
import java.util.Set;

import com.gemstone.gemfire.SystemFailure;
import com.gemstone.gemfire.distributed.internal.DM;
import com.gemstone.gemfire.distributed.internal.DistributionManager;
import com.gemstone.gemfire.distributed.internal.DistributionMessage;
import com.gemstone.gemfire.distributed.internal.HighPriorityDistributionMessage;
import com.gemstone.gemfire.distributed.internal.InternalDistributedSystem;
import com.gemstone.gemfire.distributed.internal.MessageWithReply;
import com.gemstone.gemfire.distributed.internal.ReplyException;
import com.gemstone.gemfire.distributed.internal.ReplyProcessor21;
import com.gemstone.gemfire.distributed.internal.membership.InternalDistributedMember;
import com.gemstone.gemfire.internal.Assert;
import com.gemstone.gemfire.distributed.internal.DistributionStats;

/**
 * A message sent to determine the most recent PartitionedRegion identity
 * @author mthomas
 * @since 5.0
 */
public final class IdentityRequestMessage extends DistributionMessage implements MessageWithReply
{
  private static final int UNINITIALIZED = -1;
  
  /**
   * This is the keeper of the latest PartitionedRegion Identity on a per VM basis
   */
  private static int latestId = UNINITIALIZED;
  
  public static synchronized void setLatestId(int newlatest) {
    if (newlatest > latestId) {
      latestId = newlatest;
    }
  }
  
  /**
   * Method public for test reasons
   * @return the latest identity
   */
  public static synchronized int getLatestId() {
    return latestId;
  }

  private int processorId;

  /** 
   * Empty constructor to conform to DataSerializer interface
   *
   */
  public IdentityRequestMessage() {}

  public IdentityRequestMessage(Set recipients, int processorId) {
    setRecipients(recipients);
    this.processorId = processorId;
  }

  @Override  
  protected void process(DistributionManager dm)
  {
    LogWriterI18n logger = null;
    try {
      logger = dm.getLoggerI18n();
      if (logger.fineEnabled()) {
        logger.fine(getClass().getName() + ": processing message " + this);
      }
      
      IdentityReplyMessage.send(getSender(), getProcessorId(), dm);        
    }
    catch (Throwable t) {
      Error err;
      if (t instanceof Error && SystemFailure.isJVMFailureError(
          err = (Error)t)) {
        SystemFailure.initiateFailure(err);
        // If this ever returns, rethrow the error. We're poisoned
        // now, so don't let this thread continue.
        throw err;
      }
      // Whenever you catch Error or Throwable, you must also
      // check for fatal JVM error (see above).  However, there is
      // _still_ a possibility that you are dealing with a cascading
      // error condition, so you also need to check to see if the JVM
      // is still usable:
      SystemFailure.checkFailure();
      logger.fine(this + " Caught throwable", t);
    }
  }

  @Override  
  public int getProcessorId()
  {
    return this.processorId;
  }
  
  
  @Override  
  public int getProcessorType()
  {
    return DistributionManager.HIGH_PRIORITY_EXECUTOR;
  }

  /**
   * Sends a <code>IdentityRequest</code> to each <code>PartitionedRegion</code> {@link com.gemstone.gemfire.internal.cache.Node}.  The
   * <code>IdentityResponse</code> is used to fetch the highest current identity value. 
   * @param recipients
   * @return the response object to wait upon
   */
  public static IdentityResponse send(Set recipients, InternalDistributedSystem is) 
  {
    Assert.assertTrue(recipients != null, "IdentityMessage NULL recipients set");
    int i = 0;
    for (Iterator ri = recipients.iterator(); ri.hasNext(); i++) {
      Assert.assertTrue(null != ri.next(), "IdenityMessage recipient " + i + " is null");
    }
    
    IdentityResponse p = new IdentityResponse(is, recipients);
    IdentityRequestMessage m = new IdentityRequestMessage(recipients, p.getProcessorId());
    is.getDistributionManager().putOutgoing(m);
    return p;
  }
  
  
  public int getDSFID() {
    return PR_IDENTITY_REQUEST_MESSAGE;
  }

  @Override  
  public void fromData(DataInput in) throws IOException, ClassNotFoundException
  {
    super.fromData(in);
    this.processorId = in.readInt();
  }

  @Override  
  public void toData(DataOutput out) throws IOException
  {
    super.toData(out);
    out.writeInt(this.processorId);
  }

  @Override  
  public String toString()
  {
    return new StringBuffer()
      .append(getClass().getName())
      .append("(sender=")
      .append(getSender())
      .append("; processorId=")
      .append(this.processorId)
      .append(")")
      .toString();
  }


  /**
   * The message that contains the <code>Integer</code> identity response to the {@link IdentityRequestMessage}
   *  
   * @author mthomas
   * @since 5.0
   */
  public static final class IdentityReplyMessage extends HighPriorityDistributionMessage {
    private int Id = UNINITIALIZED;
  
    /** The shared obj id of the ReplyProcessor */
    private int processorId;
    
    /**
     * Empty constructor to conform to DataSerializable interface 
     */
    public IdentityReplyMessage() {
    }
  
    private IdentityReplyMessage(int processorId)
    {
      this.processorId = processorId;
      this.Id = IdentityRequestMessage.getLatestId();
    }
    
    public static void send(InternalDistributedMember recipient, int processorId, DM dm) 
    {
      Assert.assertTrue(recipient != null, "IdentityReplyMessage NULL reply message");
      IdentityReplyMessage m = new IdentityReplyMessage(processorId);
      m.setRecipient(recipient);
      dm.putOutgoing(m);
    }

    @Override  
    protected void process(final DistributionManager dm) {
      final long startTime = getTimestamp();
      LogWriterI18n l = dm.getLoggerI18n();
      if (DistributionManager.VERBOSE) {
        l.fine(getClass().getName() + " process invoking reply processor with processorId:" + this.processorId);
      }
      
      ReplyProcessor21 processor = ReplyProcessor21.getProcessor(this.processorId);
      
      if (processor == null) {
        if (DistributionManager.VERBOSE) {
          l.info(LocalizedStrings.IdentityRequestMessage_0_PROCESSOR_NOT_FOUND, getClass().getName());
        }
        return;
      }
      processor.process(this);
      
      if (DistributionManager.VERBOSE) {
        LogWriterI18n logger = dm.getLoggerI18n();
        logger.info(LocalizedStrings.IdentityRequestMessage_0__PROCESSED__1, new Object[] {processor, this});
      }
      dm.getStats().incReplyMessageTime(DistributionStats.getStatTime()-startTime);
    }
    
    @Override  
    public void toData(DataOutput out) throws IOException {
      super.toData(out);
      out.writeInt(this.processorId);
      out.writeInt(this.Id);
    }

  public int getDSFID() {
    return PR_IDENTITY_REPLY_MESSAGE;
  }

  @Override  
    public void fromData(DataInput in)
      throws IOException, ClassNotFoundException {
      super.fromData(in);
      this.processorId = in.readInt();
      this.Id = in.readInt();
    }
    
  @Override  
    public String toString()
    {
      return new StringBuffer()
        .append(getClass().getName())
        .append("(sender=")
        .append(getSender())
        .append("; processorId=")
        .append(this.processorId)
        .append("; PRId=").append(getId())
        .append(")")
        .toString();
    }

    /**
     * Fetch the current Identity number  
     * @return the identity Integer from the sender or null if the sender did not have the Integer initialized 
     */
    public Integer getId() {
      if (this.Id == UNINITIALIZED) {
        return null;
      }
      return Integer.valueOf(this.Id);
    }
  }

  /**
   * The response to a {@link IdentityRequestMessage} use {@link #waitForId()} to 
   * capture the identity
   * @author mthomas
   * @since 5.0
   */
  public static class IdentityResponse extends ReplyProcessor21  {
    private Integer returnValue;
    
    public IdentityResponse(InternalDistributedSystem system, Set initMembers) {
      super(system, initMembers);
      int localIdent = IdentityRequestMessage.getLatestId(); 
      if (localIdent != UNINITIALIZED) {
        this.returnValue = Integer.valueOf(localIdent);
      }
    }

    @Override  
    public void process(DistributionMessage msg)
    {
      try {
        if (msg instanceof IdentityReplyMessage) {
          IdentityReplyMessage reply = (IdentityReplyMessage) msg;
          final Integer remoteId = reply.getId();
          synchronized(this) {
            if (remoteId !=null) {
              if (this.returnValue == null) {
                this.returnValue = remoteId;
              } else {
                if (remoteId.intValue() > this.returnValue.intValue()) {
                  this.returnValue = remoteId;
                }
              }
            }
          }
          if (DistributionManager.VERBOSE) {
            getDistributionManager().getLoggerI18n().fine(getClass().getName() + " return value is " + 
                this.returnValue);
          }
        }
      } finally {
        super.process(msg);
      }
    }

    /**
     * Fetch the next <code>PartitionedRegion</code> identity, used to uniquely identify (globally) each instance of a 
     * <code>PartitionedRegion</code>  
     * @return the next highest Integer for the <code>PartitionedRegion</code> or null if this is the first identity
     * 
     * @see PartitionMessage#getRegionId()
     */
    public Integer waitForId() {
      try {
        waitForRepliesUninterruptibly();
      }
      catch (ReplyException e) {
        getDistributionManager().getLoggerI18n().fine(getClass().getName() + " waitBucketSizes ignoring exception", e);
      }
      synchronized(this) {
        return this.returnValue;
      }
    }
  }

}
