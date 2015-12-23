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
package com.gemstone.sequence;

/**
 * An interface for mapping a lifeline name to a shorter version of the same
 * line. This could also consolodate multiple lifelines onto a single line.
 * 
 * The most common case for this is that a lifeline represents a VM that is
 * restarted several times. Eg time, the line name changes, but we want to put
 * all of the states for that "logical" vm on the same line.
 * @author dsmith
 *
 */
public interface LineMapper {
  
  /**
   * Return the short name for this lifeline.
   */
  public String getShortNameForLine(String lineName);

}
