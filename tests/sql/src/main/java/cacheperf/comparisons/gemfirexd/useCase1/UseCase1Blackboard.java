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

package cacheperf.comparisons.gemfirexd.useCase1;

import hydra.blackboard.Blackboard;

public class UseCase1Blackboard extends Blackboard {

  private static UseCase1Blackboard blackboard;

  public static int stopSignal;

  public static int pauseSignal;
  public static int pauseCount;

  public static int drainSignal;
  public static int drainedSignal;

  public static int maxFsMessageId;

  public UseCase1Blackboard() {
  }

  public UseCase1Blackboard(String name, String type) {
    super(name, type, UseCase1Blackboard.class);
  }

  public static synchronized UseCase1Blackboard getInstance() {
    if (blackboard == null) {
      blackboard = new UseCase1Blackboard("UseCase1Blackboard", "rmi");
    }
    return blackboard;
  }
}
