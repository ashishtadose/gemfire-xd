/*

   Derby - Class com.pivotal.gemfirexd.internal.iapi.sql.dictionary.UniqueSQLObjectDescriptor

   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to you under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

 */

package com.pivotal.gemfirexd.internal.iapi.sql.dictionary;


import com.pivotal.gemfirexd.internal.catalog.UUID;
import com.pivotal.gemfirexd.internal.iapi.error.StandardException;

/**
 * This is a descriptor for something that is a 
 * SQL object that has the following properties:
 * <UL>
 *	<LI> resides in a schema </LI>
 *	<LI> has a name (that is unique when combined with schema) </LI>
 *	<LI> has a unique identifier (UUID) </LI>
 * </UL>
 *
 * UUIDS.
 *
 */
public interface UniqueSQLObjectDescriptor extends UniqueTupleDescriptor
{
	/**
	 * Get the name of this object.  E.g. for a table descriptor,
	 * this will be the table name.
	 * 
	 * @return the name
	 */
	public String getName();

	/**
	 * Get the objects schema descriptor
	 *
	 * @return the schema descriptor
	 *
	 * @exception StandardException on error
	 */
	public SchemaDescriptor getSchemaDescriptor()
		throws StandardException;
}
