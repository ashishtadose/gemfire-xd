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
package com.gemstone.gemfire.management.internal;

import java.util.Collections;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

import javax.management.ObjectName;

import com.gemstone.gemfire.distributed.DistributedMember;
import com.gemstone.gemfire.distributed.internal.InternalDistributedSystem;
import com.gemstone.gemfire.i18n.LogWriterI18n;
import com.gemstone.gemfire.management.ManagementException;


/**
 * This class is a repository of all proxy related information multiple indices
 * are provided for searching This searching capability will ease while various
 * proxy ops. It will also be used while filter addition/ removal if dynamic
 * filters are going to be supported.
 * 
 * @author rishim
 * 
 */

public class MBeanProxyInfoRepository {

  private LogWriterI18n logger;

  /**
   * This index will keep a map between old object name and proxy info
   */
  private Map<ObjectName, ProxyInfo> objectNameIndex;

  /**
   * This index will keep a map between old object name and proxy info
   */
  private Map<DistributedMember, Set<ObjectName>> memberIndex;

  protected MBeanProxyInfoRepository() {

    objectNameIndex = new ConcurrentHashMap<ObjectName, ProxyInfo>();
    memberIndex = new ConcurrentHashMap<DistributedMember, Set<ObjectName>>();
    logger = InternalDistributedSystem.getLoggerI18n();
  }

  /**
   * Add the {@link ProxyInfo} into repository for future quick access
   * 
   * @param member
   *          Distributed Member
   * @param proxyInfo
   *          Proxy Info instance
   */
  protected void addProxyToRepository(DistributedMember member,
      ProxyInfo proxyInfo) {
    ObjectName objectName = proxyInfo.getObjectName();
    if (logger.finestEnabled()) {
      logger.finest("ADDED TO PROXY REPO : "
          + proxyInfo.getObjectName().toString());
    }

    objectNameIndex.put(objectName, proxyInfo);
    if (memberIndex.get(member) != null) {
      memberIndex.get(member).add(proxyInfo.getObjectName());
    } else {
      Set<ObjectName> proxyInfoSet = new CopyOnWriteArraySet<ObjectName>();
      proxyInfoSet.add(proxyInfo.getObjectName());
      memberIndex.put(member, proxyInfoSet);
    }

  }

  /**
   * Finds the proxy instance by {@link javax.management.ObjectName}
   * 
   * @param objectName
   * @param interfaceClass
   * @return instance of proxy
   */
  protected <T> T findProxyByName(ObjectName objectName, Class<T> interfaceClass) {
    if (logger.fineEnabled()) {
      logger.fine("findProxyByName : "
          + objectName.toString());
      logger.fine("findProxyByName Existing ObjectNames  : " + objectNameIndex.keySet().toString());
    }

    ProxyInfo proxyInfo = objectNameIndex.get(objectName);
    if (proxyInfo != null) {
      return interfaceClass.cast(proxyInfo.getProxyInstance());
    }else{
      return null;
    }
    

  }
  
  /**
   * Finds the proxy instance by {@link javax.management.ObjectName}
   * 
   * @param objectName
   * @return instance of proxy
   */
  protected ProxyInfo findProxyInfo(ObjectName objectName) {
    if (logger.finestEnabled()) {
      logger.finest("SEARCHING FOR PROXY INFO N REPO FOR MBEAN : "
          + objectName.toString());
    }
    ProxyInfo proxyInfo = objectNameIndex.get(objectName);
   
    return proxyInfo;
  }

  /**
   * Finds the set of proxy instances by {@link com.gemstone.gemfire.distributed.DistributedMember} 
   * 
   * @param member
   *          DistributedMember
   * @return A set of proxy instance on which user can invoke operations as
   *         defined by the proxy interface
   */
  protected Set<ObjectName> findProxySet(DistributedMember member) {
    if (logger.finestEnabled()) {
      logger.finest("SEARCHING PROXIES FOR MEMBER : " + member.getId());
    }

    Set<ObjectName> proxyInfoSet = memberIndex.get(member);
    if (proxyInfoSet != null) {
      return Collections.unmodifiableSet(proxyInfoSet);
    }else{
      return Collections.emptySet();
    }
  }

  /**
   * Removes a proxy of a given
   * {@link com.gemstone.gemfire.distributed.DistributedMember} and given
   * {@link javax.management.ObjectName}
   * 
   * @param member
   *          DistributedMember
   * @param objectName
   *          MBean name
   */
  protected void removeProxy(DistributedMember member, ObjectName objectName) {
    ProxyInfo info = objectNameIndex.remove(objectName);
    Set<ObjectName> proxyInfoSet = memberIndex.get(member);
    if (proxyInfoSet == null || proxyInfoSet.size() == 0) {
      return;
    }
    if (proxyInfoSet.contains(objectName)) {
      proxyInfoSet.remove(objectName);
    }

  }

}