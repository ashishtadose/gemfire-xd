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
package com.gemstone.gemfire.management.internal.web.controllers;

import com.gemstone.gemfire.internal.lang.StringUtils;
import com.gemstone.gemfire.management.internal.cli.i18n.CliStrings;
import com.gemstone.gemfire.management.internal.cli.util.CommandStringBuilder;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * The FunctionCommandsController class implements GemFire Management REST API web service endpoints for the
 * Gfsh Function Commands.
 * <p/>
 * @author John Blum
 * @see com.gemstone.gemfire.management.internal.cli.commands.FunctionCommands
 * @see com.gemstone.gemfire.management.internal.web.controllers.AbstractCommandsController
 * @see org.springframework.stereotype.Controller
 * @see org.springframework.web.bind.annotation.PathVariable
 * @see org.springframework.web.bind.annotation.RequestMapping
 * @see org.springframework.web.bind.annotation.RequestMethod
 * @see org.springframework.web.bind.annotation.RequestParam
 * @see org.springframework.web.bind.annotation.ResponseBody
 * @since 7.5
 */
@Controller("functionController")
@RequestMapping("/v1")
@SuppressWarnings("unused")
public class FunctionCommandsController extends AbstractCommandsController {

  @RequestMapping(value = "/functions", method = RequestMethod.GET)
  @ResponseBody
  public String listFunctions(@RequestParam(value = CliStrings.LIST_FUNCTION__GROUP, required = false) final String[] groups,
                              @RequestParam(value = CliStrings.LIST_FUNCTION__MEMBER, required = false) final String[] members,
                              @RequestParam(value = CliStrings.LIST_FUNCTION__MATCHES, required = false) final String matches)
  {
    final CommandStringBuilder command = new CommandStringBuilder(CliStrings.LIST_FUNCTION);

    if (hasValue(groups)) {
      command.addOption(CliStrings.LIST_FUNCTION__GROUP, StringUtils.concat(groups, StringUtils.COMMA_DELIMITER));
    }

    if (hasValue(members)) {
      command.addOption(CliStrings.LIST_FUNCTION__MEMBER, StringUtils.concat(members, StringUtils.COMMA_DELIMITER));
    }

    if (hasValue(matches)) {
      command.addOption(CliStrings.LIST_FUNCTION__MATCHES, matches);
    }

    return processCommand(command.toString());
  }

  // TODO add Async functionality
  @RequestMapping(value = "/functions/{id}", method = RequestMethod.POST)
  @ResponseBody
  public String executeFunction(@PathVariable("id") final String functionId,
                                @RequestParam(value = CliStrings.EXECUTE_FUNCTION__ONGROUP, required = false) final String groupName,
                                @RequestParam(value = CliStrings.EXECUTE_FUNCTION__ONMEMBER, required = false) final String memberNameId,
                                @RequestParam(value = CliStrings.EXECUTE_FUNCTION__ONREGION, required = false) final String regionNamePath,
                                @RequestParam(value = CliStrings.EXECUTE_FUNCTION__ARGUMENTS, required = false) final String[] arguments,
                                @RequestParam(value = CliStrings.EXECUTE_FUNCTION__FILTER, required = false) final String filter,
                                @RequestParam(value = CliStrings.EXECUTE_FUNCTION__RESULTCOLLECTOR, required = false) final String resultCollector)
  {
    final CommandStringBuilder command = new CommandStringBuilder(CliStrings.EXECUTE_FUNCTION);

    command.addOption(CliStrings.EXECUTE_FUNCTION__ID, functionId);

    if (hasValue(groupName)) {
      command.addOption(CliStrings.EXECUTE_FUNCTION__ONGROUP, groupName);
    }

    if (hasValue(memberNameId)) {
      command.addOption(CliStrings.EXECUTE_FUNCTION__ONMEMBER, memberNameId);
    }

    if (hasValue(regionNamePath)) {
      command.addOption(CliStrings.EXECUTE_FUNCTION__ONREGION, regionNamePath);
    }

    if (hasValue(arguments)) {
      command.addOption(CliStrings.EXECUTE_FUNCTION__ARGUMENTS, StringUtils.concat(arguments, StringUtils.COMMA_DELIMITER));
    }

    if (hasValue(filter)) {
      command.addOption(CliStrings.EXECUTE_FUNCTION__FILTER, filter);
    }

    if (hasValue(resultCollector)) {
      command.addOption(CliStrings.EXECUTE_FUNCTION__RESULTCOLLECTOR, resultCollector);
    }

    return processCommand(command.toString());
  }

  @RequestMapping(value = "/functions/{id}", method = RequestMethod.DELETE)
  @ResponseBody
  public String destroyFunction(@PathVariable("id") final String functionId,
                                @RequestParam(value = CliStrings.DESTROY_FUNCTION__ONGROUP, required = false) final String groupName,
                                @RequestParam(value = CliStrings.DESTROY_FUNCTION__ONMEMBER, required = false) final String memberNameId)
  {
    final CommandStringBuilder command = new CommandStringBuilder(CliStrings.DESTROY_FUNCTION);

    command.addOption(CliStrings.DESTROY_FUNCTION__ID, functionId);

    if (hasValue(groupName)) {
      command.addOption(CliStrings.DESTROY_FUNCTION__ONGROUP, groupName);
    }

    if (hasValue(memberNameId)) {
      command.addOption(CliStrings.DESTROY_FUNCTION__ONMEMBER, memberNameId);
    }

    return processCommand(command.toString());
  }

}