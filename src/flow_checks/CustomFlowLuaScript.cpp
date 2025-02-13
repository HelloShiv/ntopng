/*
 *
 * (C) 2013-22 - ntop.org
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#include "ntop_includes.h"
#include "flow_checks_includes.h"

/* ***************************************************** */

CustomFlowLuaScript::CustomFlowLuaScript() : FlowCheck(ntopng_edition_community,
						       false /* All interfaces */,
						       false /* Don't exclude for nEdge */,
						       false /* NOT only for nEdge */,
						       true /* has_protocol_detected */,
						       false /* has_periodic_update */,
						       false /* has_flow_end */) {
  disabled = false;
}

/* ***************************************************** */

LuaEngine* CustomFlowLuaScript::initVM() {
  const char *script_path = "scripts/callbacks/checks/flows/custom_flow_lua_script.lua";
  char where[256];
  struct stat s;

  snprintf(where, sizeof(where), "%s/%s", ntop->get_install_dir(), script_path);

  if(stat(where, &s) != 0) {
    if(!disabled) {
      ntop->getTrace()->traceEvent(TRACE_NORMAL, "Unable to find script %s: ignored `Flow User Check Script` flow check", where);
      disabled = true;
    }
    
    return(NULL);
  } else {
    LuaEngine *lua;

    try {
      lua = new LuaEngine(NULL);
      lua->load_script((char*)where, NULL /* NetworkInterface filled later via lua->setFlow(f); */);
      ntop->getTrace()->traceEvent(TRACE_NORMAL, "Loaded custom user script %s", where);
    } catch(std::bad_alloc& ba) {
      ntop->getTrace()->traceEvent(TRACE_ERROR, "Unable to start Lua interpreter.");
    }

    return(lua);
  }
}
/* ***************************************************** */

CustomFlowLuaScript::~CustomFlowLuaScript() {

}

/* ***************************************************** */

void CustomFlowLuaScript::protocolDetected(Flow *f) {
  LuaEngine *lua;

  if(!f)
    return;
  else {
    lua = f->getInterface()->getCustomFlowLuaScript();

    if(lua == NULL) {
      lua = initVM();
      f->getInterface()->setCustomFlowLuaScript(lua);
    }
  }

  if(lua != NULL) {
    if(false) {
      char buf[128];

      ntop->getTrace()->traceEvent(TRACE_NORMAL, "Running Lua script on %s", f->print(buf, sizeof(buf)));
    }

    lua->setFlow(f);
    lua->run_loaded_script(); /* Run script */

    if(f->isCustomFlowAlertTriggered()) {
      FlowAlertType alert_type = CustomFlowLuaScriptAlert::getClassType();
      u_int8_t c_score, s_score;
      risk_percentage cli_score_pctg = CLIENT_FAIR_RISK_PERCENTAGE;

      computeCliSrvScore(alert_type, cli_score_pctg, &c_score, &s_score);

      f->triggerAlertAsync(alert_type, c_score, s_score);
    }
  }
}

/* ***************************************************** */

FlowAlert *CustomFlowLuaScript::buildAlert(Flow *f) {
  CustomFlowLuaScriptAlert *alert = new CustomFlowLuaScriptAlert(this, f);

  alert->setAlertMessage(f->getCustomFlowAlertMessage());
  alert->setAlertScore(f->getCustomFlowAlertScore());

  return alert;
}

/* ***************************************************** */

/* Sample configuration:
  "script_conf": {
    "severity": {
      "syslog_severity": 3,
      "severity_id": 5,
      "i18n_title": "alerts_dashboard.error",
      "emoji": "❗",
      "icon": "fas fa-exclamation-triangle text-danger",
      "label": "badge-danger"
    }
  }
*/

bool CustomFlowLuaScript::loadConfiguration(json_object *config) {
  FlowCheck::loadConfiguration(config); /* Parse parameters in common */

  /* Parse additional parameters */

  return(true);
}

/* ***************************************************** */
