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
package com.gemstone.gemfire.cache.client.internal;

import java.io.IOException;

import com.gemstone.gemfire.DataSerializer;
import com.gemstone.gemfire.SerializationException;
import com.gemstone.gemfire.i18n.LogWriterI18n;
import com.gemstone.gemfire.internal.InternalDataSerializer.SerializerAttributesHolder;
import com.gemstone.gemfire.internal.cache.BridgeObserver;
import com.gemstone.gemfire.internal.cache.BridgeObserverHolder;
import com.gemstone.gemfire.internal.cache.EventID;
import com.gemstone.gemfire.internal.cache.tier.MessageType;
import com.gemstone.gemfire.internal.cache.tier.sockets.Message;
import com.gemstone.gemfire.internal.util.BlobHelper;

public class RegisterDataSerializersOp {

  public static void execute(ExecutablePool pool,
      DataSerializer[] dataSerializers, EventID eventId) {
    AbstractOp op = new RegisterDataSerializersOpImpl(pool.getLoggerI18n(),
        dataSerializers, eventId);
    pool.execute(op);
  }
  
  public static void execute(ExecutablePool pool,
      SerializerAttributesHolder[] holders, EventID eventId) {
    AbstractOp op = new RegisterDataSerializersOpImpl(pool.getLoggerI18n(),
        holders, eventId);
    pool.execute(op);
  }
  
  private RegisterDataSerializersOp() {
    // no instances allowed
  }
  
  private static class RegisterDataSerializersOpImpl extends AbstractOp {

    /**
     * @throws com.gemstone.gemfire.SerializationException if serialization fails
     */
    public RegisterDataSerializersOpImpl(LogWriterI18n lw,
        DataSerializer[] dataSerializers,
                                       EventID eventId) {
      super(lw, MessageType.REGISTER_DATASERIALIZERS, dataSerializers.length * 2 + 1);
      for(int i = 0; i < dataSerializers.length; i++) {
        DataSerializer dataSerializer = dataSerializers[i];
         // strip '.class' off these class names
        String className = dataSerializer.getClass().toString().substring(6);
        try {
          getMessage().addBytesPart(BlobHelper.serializeToBlob(className));
        } catch (IOException ex) {
          throw new SerializationException("failed serializing object", ex);
        }
        getMessage().addIntPart(dataSerializer.getId());
      }
      getMessage().addBytesPart(eventId.calcBytes());
      // // CALLBACK FOR TESTING PURPOSE ONLY ////
      if (PoolImpl.IS_INSTANTIATOR_CALLBACK) {
        BridgeObserver bo = BridgeObserverHolder.getInstance();
        bo.beforeSendingToServer(eventId);
      }
   }
    
    /**
     * @throws SerializationException
     *           Thrown when serialization fails.
     */
    public RegisterDataSerializersOpImpl(LogWriterI18n lw,
        SerializerAttributesHolder[] holders, EventID eventId) {
      super(lw, MessageType.REGISTER_DATASERIALIZERS, holders.length * 2 + 1);
      for (int i = 0; i < holders.length; i++) {
        try {
          getMessage().addBytesPart(
              BlobHelper.serializeToBlob(holders[i].getClassName()));
        } catch (IOException ex) {
          throw new SerializationException("failed serializing object", ex);
        }
        getMessage().addIntPart(holders[i].getId());
      }
      getMessage().addBytesPart(eventId.calcBytes());
      // // CALLBACK FOR TESTING PURPOSE ONLY ////
      if (PoolImpl.IS_INSTANTIATOR_CALLBACK) {
        BridgeObserver bo = BridgeObserverHolder.getInstance();
        bo.beforeSendingToServer(eventId);
      }
    }

    @Override
    protected Object processResponse(Message msg) throws Exception {
      processAck(msg, "registerDataSerializers");
      return null;
    }
    
    @Override
    protected boolean isErrorResponse(int msgType) {
      return false;
    }
    @Override
    protected long startAttempt(ConnectionStats stats) {
      return stats.startRegisterDataSerializers();
    }
    @Override
    protected void endSendAttempt(ConnectionStats stats, long start) {
      stats.endRegisterDataSerializersSend(start, hasFailed());
    }
    @Override
    protected void endAttempt(ConnectionStats stats, long start) {
      stats.endRegisterDataSerializers(start, hasTimedOut(), hasFailed());
    }
    @Override
    protected void processSecureBytes(Connection cnx, Message message)
        throws Exception {
    }
    @Override
    protected boolean needsUserId() {
      return false;
    }
    @Override
    protected void sendMessage(Connection cnx) throws Exception {
      getMessage().setEarlyAck((byte)(getMessage().getEarlyAckByte() & Message.MESSAGE_HAS_SECURE_PART));
      getMessage().send(false);
    }
  }
}
