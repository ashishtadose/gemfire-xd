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
package com.pivotal.gemfirexd.internal.engine.ddl.callbacks.messages;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.sql.SQLException;

import com.gemstone.gemfire.DataSerializer;
import com.gemstone.gemfire.LogWriter;
import com.gemstone.gemfire.internal.cache.execute.InternalFunctionInvocationTargetException;
import com.pivotal.gemfirexd.internal.engine.Misc;
import com.pivotal.gemfirexd.internal.engine.GfxdSerializable;
import com.pivotal.gemfirexd.internal.engine.ddl.callbacks.CallbackProcedures;
import com.pivotal.gemfirexd.internal.engine.ddl.wan.messages.AbstractGfxdReplayableMessage;
import com.pivotal.gemfirexd.internal.engine.distributed.FunctionExecutionException;
import com.pivotal.gemfirexd.internal.engine.distributed.utils.GemFireXDUtils;
import com.pivotal.gemfirexd.internal.iapi.error.StandardException;
import com.pivotal.gemfirexd.internal.impl.jdbc.EmbedConnection;

public class GfxdRemoveWriterMessage extends AbstractGfxdReplayableMessage {

  private static final long serialVersionUID = -3282239476697354367L;

  private String schema;

  private String table;

  public GfxdRemoveWriterMessage() {
  }

  public GfxdRemoveWriterMessage(String schema, String table) {
    this.schema = schema;
    this.table = table;
  }

  @Override
  public void execute() throws StandardException {
    LogWriter logger = Misc.getGemFireCache().getLoggerI18n()
        .convertToLogWriter();
    EmbedConnection conn = null;
    boolean contextSet = false;
    try {
      conn = GemFireXDUtils.getTSSConnection(true, true, false);
      conn.getTR().setupContextStack();
      contextSet = true;
      if (logger.infoEnabled()) {
        logger.info("GfxdRemoveWriterMessage: Executing with fields as: "
            + this.toString());
      }
      CallbackProcedures.removeGfxdCacheWriterLocally(CallbackProcedures
          .getContainerForTable(this.schema, this.table));
    } catch (Exception ex) {
      if (logger.fineEnabled()) {
        logger.fine("GfxdRemoveWriterMessage#execute: exception encountered",
            ex);
      }
      if (GemFireXDUtils.retryToBeDone(ex)) {
        throw new InternalFunctionInvocationTargetException(ex);
      }
      throw new FunctionExecutionException(ex);
    } finally {
      if (contextSet) {
        try {
          conn.internalCommit();
        } catch (SQLException ex) {
          if (logger.fineEnabled()) {
            logger.fine(
                "GfxdRemoveWriterMessage#execute: exception encountered", ex);
          }
        }
        conn.getTR().restoreContextStack();
      }
    }
  }

  @Override
  public byte getGfxdID() {
    return GfxdSerializable.REMOVE_WRITER_MSG;
  }

  @Override
  public void toData(DataOutput out)
      throws IOException {
    super.toData(out);
    DataSerializer.writeString(this.schema, out);
    DataSerializer.writeString(this.table, out);
  }

  @Override
  public void fromData(DataInput in)
      throws IOException, ClassNotFoundException {
    super.fromData(in);
    this.schema = DataSerializer.readString(in);
    this.table = DataSerializer.readString(in);
  }

  @Override
  public void appendFields(final StringBuilder sb) {
    super.appendFields(sb);
    sb.append("; schema = ");
    sb.append(this.schema);
    sb.append("; table = ");
    sb.append(this.table);
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public boolean shouldBeConflated() {
    return true;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public String getRegionToConflate() {
    return this.schema + '.' + this.table;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public Object getKeyToConflate() {
    return GfxdSetWriterMessage.CONFLATION_KEY_PREFIX;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public Object getValueToConflate() {
    return null;
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public String getSQLStatement() {
    final StringBuilder sb = new StringBuilder();
    return sb.append("SYS.REMOVE_WRITER('").append(this.schema).append("','")
        .append(this.table).append("')").toString();
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public String getSchemaName() {
    return this.schema;
  }
}
