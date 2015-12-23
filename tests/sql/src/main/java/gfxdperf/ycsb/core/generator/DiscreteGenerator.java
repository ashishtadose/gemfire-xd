/**
 * Copyright (c) 2010 Yahoo! Inc. All rights reserved.
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
package gfxdperf.ycsb.core.generator;

import gfxdperf.ycsb.core.Utils;
import gfxdperf.ycsb.core.WorkloadException;

import gfxdperf.PerfTestException;

import java.util.Vector;

/**
 * Generates a distribution by choosing from a discrete set of values.
 */
public class DiscreteGenerator extends Generator
{
	class Pair
	{
		public double _weight;
		public String _value;

		Pair(double weight, String value)
		{
			_weight=weight;
			_value=value;
		}
	}

	Vector<Pair> _values;
	String _lastvalue;

	public DiscreteGenerator()
	{
		_values=new Vector<Pair>();
		_lastvalue=null;
	}

	/**
	 * Generate the next string in the distribution.
	 */
	public String nextString()
	{
        // @todo lises optimize this mess
		double sum=0;

		for (Pair p : _values)
		{
			sum+=p._weight;
		}

		double val=Utils.random().nextDouble();

		for (Pair p : _values)
		{
			if (val<p._weight/sum)
			{
				return p._value;
			}

			val-=p._weight/sum;
		}

		//should never get here.
		String s = "Unable to process " + _values;
                throw new PerfTestException(s);
	}

	/**
	 * If the generator returns numeric (integer) values, return the next value as an int. Default is to return -1, which
	 * is appropriate for generators that do not return numeric values.
	 * 
	 * @throws WorkloadException if this generator does not support integer values
	 */
	public int nextInt() throws WorkloadException
	{
		throw new WorkloadException("DiscreteGenerator does not support nextInt()");
	}

	/**
	 * Return the previous string generated by the distribution; e.g., returned from the last nextString() call. 
	 * Calling lastString() should not advance the distribution or have any side effects. If nextString() has not yet 
	 * been called, lastString() should return something reasonable.
	 */
	public String lastString()
	{
		if (_lastvalue==null)
		{
			_lastvalue=nextString();
		}
		return _lastvalue;
	}

	public void addValue(double weight, String value)
	{
		_values.add(new Pair(weight,value));
	}

}
