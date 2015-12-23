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
/**
 * 
 */
package com.gemstone.gemfire.distributed.internal;

import java.util.Map;

import com.gemstone.gemfire.cache.CacheException;
import com.gemstone.gemfire.cache30.CacheSerializableRunnable;
import com.gemstone.gemfire.distributed.DistributedMember;
import com.gemstone.gemfire.distributed.internal.membership.jgroup.JGroupMembershipManager;
import com.gemstone.gemfire.distributed.internal.membership.jgroup.MembershipManagerHelper;
import com.gemstone.org.jgroups.Address;
import com.gemstone.org.jgroups.Event;
import com.gemstone.org.jgroups.JChannel;
import com.gemstone.org.jgroups.Message;
import com.gemstone.org.jgroups.protocols.GemFireTimeSync;
import com.gemstone.org.jgroups.protocols.GemFireTimeSync.GFTimeSyncHeader;
import com.gemstone.org.jgroups.protocols.GemFireTimeSync.TestHook;
import com.gemstone.org.jgroups.stack.IpAddress;
import com.gemstone.org.jgroups.stack.Protocol;
import com.gemstone.org.jgroups.stack.ProtocolStack;

import dunit.DistributedTestCase;
import dunit.Host;
import dunit.SerializableCallable;
import dunit.VM;

/**
 * The dunit test is testing time offset set at
 * {@link DistributionManager#cacheTimeDelta}
 * @author shobhit
 *
 */
public class DistributionManagerTimeDUnitTest extends DistributedTestCase {

  public final int SKEDNESS = 10;
  
  /**
   * @param name
   */
  public DistributionManagerTimeDUnitTest(String name) {
    super(name);
  }

  public void testDistributionManagerTimeSync() {
    disconnectAllFromDS();

    Host host = Host.getHost(0);
    VM vm0 = host.getVM(0);
    VM vm1 = host.getVM(1);
    VM vm2 = host.getVM(2);
    
    // Start distributed system in all VMs.
    
    long vmtime0 = (Long) vm0.invoke(new SerializableCallable() {
      
      @Override
      public Object call() throws Exception {
        InternalDistributedSystem system = getSystem();
        DistributionManager dm = (DistributionManager) system.getDistributionManager();
        long timeOffset = dm.getCacheTimeOffset();
        return timeOffset;
      }
    });
    
    long vmtime1 = (Long) vm1.invoke(new SerializableCallable() {
      
      @Override
      public Object call() throws Exception {
        
        InternalDistributedSystem system = getSystem();
        DistributionManager dm = (DistributionManager) system.getDistributionManager();
        long timeOffset = dm.getCacheTimeOffset();
        return timeOffset;
      }
    });
    
    long vmtime2 = (Long) vm2.invoke(new SerializableCallable() {
      
      @Override
      public Object call() throws Exception {
        
        InternalDistributedSystem system = getSystem();
        DistributionManager dm = (DistributionManager) system.getDistributionManager();
        long timeOffset = dm.getCacheTimeOffset();
        return timeOffset;
      }
    });

    getLogWriter().info("Offsets for VM0: " + vmtime0 + " VM1: " + vmtime1 + " and VM2: " +vmtime2);

    // verify if they are skewed by more than 1 milli second.
    int diff1 = (int) (vmtime0 - vmtime1);
    int diff2 = (int) (vmtime1 - vmtime2);
    int diff3 = (int) (vmtime2 - vmtime0);
    
    if ((diff1 > SKEDNESS || diff1 < -SKEDNESS) || (diff2 > SKEDNESS || diff2 < -SKEDNESS) || (diff3 > SKEDNESS || diff3 < -SKEDNESS)) {
      fail("Clocks are skewed by more than " + SKEDNESS + " ms");
    }
  }

  public void testDistributionManagerTimeSyncAfterJoinDone() {
    disconnectAllFromDS();
    
    Host host = Host.getHost(0);
    VM vm0 = host.getVM(0);
    VM vm1 = host.getVM(1);
    VM vm2 = host.getVM(2);
    
    // Start distributed system in all VMs.
    
    vm0.invoke(new CacheSerializableRunnable("Starting vm0") {
      @Override
      public void run2() {
        getSystem();
      }
    });
    
    vm1.invoke(new CacheSerializableRunnable("Starting vm1") {
      @Override
      public void run2() {
        getSystem();
      }
    });

    vm2.invoke(new CacheSerializableRunnable("Starting vm2") {
      @Override
      public void run2() {
        getSystem();
      }
    });
    
    long vmtime0 = (Long) getTimeOffset(vm0);    
    long vmtime1 = (Long) getTimeOffset(vm1);    
    long vmtime2 = (Long) getTimeOffset(vm2);
    
    getLogWriter().info("Offsets for VM0: " + vmtime0 + " VM1: " + vmtime1 + " and VM2: " +vmtime2);

    // verify if they are skewed by more than 1 milli second.
    int diff1 = (int) (vmtime0 - vmtime1);
    int diff2 = (int) (vmtime1 - vmtime2);
    int diff3 = (int) (vmtime2 - vmtime0);
    
    if ((diff1 > SKEDNESS || diff1 < -SKEDNESS) || (diff2 > SKEDNESS || diff2 < -SKEDNESS) || (diff3 > SKEDNESS || diff3 < -SKEDNESS)) {
      fail("Clocks are skewed by more than " + SKEDNESS + " ms");
    }
  }

  public Object getTimeOffset(VM vm) {
    return vm.invoke(new SerializableCallable() {
      
      @Override
      public Object call() throws Exception {
        InternalDistributedSystem system = getSystem();
        JChannel jchannel = MembershipManagerHelper.getJChannel(system);

        final UnitTestHook gftsTestHook = new UnitTestHook();
        Protocol prot = jchannel.getProtocolStack().findProtocol("GemFireTimeSync");
        GemFireTimeSync gts = (GemFireTimeSync)prot;
        gts.setTestHook(gftsTestHook);
        //Let the syncMessages reach to all VMs for new offsets.
        waitForCriterion(new WaitCriterion() {
          
          @Override
          public boolean done() {
            return gftsTestHook.getBarrier() == GemFireTimeSync.OFFSET_RESPONSE;
          }
          
          @Override
          public String description() {
            return "Waiting for this node to get time offsets from co-ordinator";
          }
        }, 500, 50, false);
        
        
        DistributionManager dm = (DistributionManager) system.getDistributionManager();
        long timeOffset = dm.getCacheTimeOffset();
        gts.setTestHook(null);
        
        return timeOffset;
      }
    });
  }

  public class UnitTestHook implements TestHook {

    private int barrier = -1;

    @Override
    public void hook(int barr) {
      this.barrier = barr;
    }

    @Override
    public void setResponses(Map<Address, GFTimeSyncHeader> responses,
        long currentTime) {
    }

    public Map<Address, GFTimeSyncHeader> getResponses() {
      return null;
    }

    public long getCurTime() {
      return 0;
    }

    public int getBarrier() {
      return barrier;
    }
  }
}
