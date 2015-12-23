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
package com.gemstone.gemfire.cache.query.internal;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import com.gemstone.gemfire.cache.query.QueryService;
import com.gemstone.gemfire.cache.query.internal.index.IndexManager;
import com.gemstone.gemfire.internal.DataSerializableFixedID;
import com.gemstone.gemfire.internal.shared.Version;

/**
 * A Token representing null.
 * @author Tejas Nomulwar
 * @since 7.5
 *
 */
public class NullToken implements DataSerializableFixedID, Comparable {

  public NullToken() {
    Support.assertState(IndexManager.NULL == null,
        "NULL constant already instantiated");
  }

  @Override
  public int compareTo(Object o) {
    // A Null token is equal to other Null token and less than any other object
    // except UNDEFINED
    if (o.equals(this)) {
      return 0;
    } else if (o.equals(QueryService.UNDEFINED)) {
      return 1;
    } else {
      return -1;
    }
  }

  @Override
  public boolean equals(Object o) {
    return o instanceof NullToken;
  }

  @Override
  public int getDSFID() {
    return NULL_TOKEN;
  }

  @Override
  public void toData(DataOutput out) throws IOException {

  }

  @Override
  public void fromData(DataInput in) throws IOException, ClassNotFoundException {
  }

  @Override
  public Version[] getSerializationVersions() {
    return null;
  }
}
