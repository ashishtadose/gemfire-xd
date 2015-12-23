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
/*
 * AbstractIndexCreationHelper.java
 *
 * Created on March 20, 2005, 8:26 PM
 */
package com.gemstone.gemfire.cache.query.internal.index;

import java.util.List;

import com.gemstone.gemfire.cache.Cache;
import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.query.*;
import com.gemstone.gemfire.cache.query.internal.CompiledValue;
import com.gemstone.gemfire.cache.query.internal.QCompiler;

/**
 * 
 * @author vaibhav
 * @author Asif
 */
public abstract class IndexCreationHelper {  
  
  public static int INDEX_QUERY_SCOPE_ID = -2;
  // Canonicalized attributes.
  //	The value in these fields is set during the execution of prepareFromClause
  // function
  //While the value of fromClause is reset in execution of prepareFromClause,
  // to canonicalized from clause
  String fromClause;
  String indexedExpression;
  String projectionAttributes;
  //String imports;
  QCompiler compiler; // use the same compiler for each query string to use
  // imports
  Cache cache;
  //Asif : The array containing the canonicalized iterator names
  //which will get reused.
  //TODO: Asif : How to make it final so that the invokers do not end up
  // modifying it
  String[] canonicalizedIteratorNames = null;
  //Asif : Array containing canonicalized iterator definitions
  //TODO: Asif : How to make it final so that the invokers do not end up
  // modifying it
  String[] canonicalizedIteratorDefinitions = null;

  IndexCreationHelper(String fromClause, String projectionAttributes,
      Cache cache) throws IndexInvalidException {
    this.cache = cache;
    // Asif:LThe fromClause,indexedExpression & projectionAttributes
    // will get modified with the canonicalized value , once the
    // constructor of derived class is over.
    this.fromClause = fromClause;
    //this.indexedExpression = indexedExpression;
    this.projectionAttributes = projectionAttributes;
    // this.imports = imports;
    this.compiler = new QCompiler(this.cache.getLoggerI18n(), true /* used from index creation*/);
    /*
     * if (this.imports != null) { this.compiler.compileImports(this.imports); }
     */
  }

  public String getCanonicalizedProjectionAttributes() {
    return projectionAttributes;
  }

  /*
   * TODO:Asif . Check if this function is required public String getImports() {
   * return this.imports; }
   */
  public String getCanonicalizedIndexedExpression() {
    return indexedExpression;
  }

  public String getCanonicalizedFromClause() {
    return fromClause;
  }

  public Cache getCache() {
    return cache;
  }

  /*
   *Asif: This function returns the canonicalized Iterator Definitions of the from
   * clauses used in Index creation
   */
  public String[] getCanonicalizedIteratorDefinitions() {
    return this.canonicalizedIteratorDefinitions;
  }
  
  boolean isMapTypeIndex() {
   return false; 
  } 
  
  public abstract List getIterators();
  abstract CompiledValue getCompiledIndexedExpression();
  abstract Region getRegion();
}
