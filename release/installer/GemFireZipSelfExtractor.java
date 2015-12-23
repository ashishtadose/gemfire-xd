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

import java.io.IOException;

public class GemFireZipSelfExtractor extends ZipSelfExtractor {
  private final static String GEMSTONE_JAR     = "gemfire.jar";
  private final static String GEMSTONE_PATTERN = ".*/com/gemstone/(?!(?:org/jgroups)|(?:gnu/trove)).*";
  private final static String JGROUPS_JAR      = "jgroups.jar";
  private final static String JGROUPS_PATTERN  = ".*/com/gemstone/org/jgroups/.*";
  private final static String TROVE_JAR        = "trove.jar";
  private final static String TROVE_PATTERN    = ".*/com/gemstone/gnu/trove/.*";

  protected void createJars() throws IOException {
    createJar(GEMSTONE_JAR, GEMSTONE_PATTERN);
    createJar(JGROUPS_JAR, JGROUPS_PATTERN);
    createJar(TROVE_JAR, TROVE_PATTERN);
  }
  
  protected String getProductJarName() {
    return "gemfire.jar";
  }
  
  protected String getInstallDirProperty() {
    return "gemfire.installer.directory";
  }
 
  protected String getInstallOpenSourceProperty() {
    return "gemfire.installer.opensource";
  }

  GemFireZipSelfExtractor() {
    super();
  }
  
  public static void main(String[] args) throws Throwable
  {
    ZipSelfExtractor zse = new GemFireZipSelfExtractor();
    zse.installProduct();
  }
}
