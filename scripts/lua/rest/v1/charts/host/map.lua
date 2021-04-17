--
-- (C) 2013-21 - ntop.org
--
local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

require "lua_utils"
local rest_utils = require("rest_utils")
local callback_utils = require("callback_utils")
local hosts_map_utils = require("hosts_map_utils")

local HostsMapMode = hosts_map_utils.HostsMapMode
local MODES = hosts_map_utils.MODES

local MAX_RADIUS_PX = 30
local MIN_RADIUS_PX = 3

local rc = rest_utils.consts.success.ok
local local_hosts = {}
local remote_hosts = {}
local max_radius = 0

local bubble_mode = tonumber(_GET["bubble_mode"]) or 0
local show_remote = _GET["show_remote"] or true

-- ###################################################

local function shrinkTable(t, max_num)
   local n = 1
   local t2 = {}
   
   for i,v in pairsByField(t, 'z', rev) do
      if(n < max_num) then
        t2[n] = v
        n = n + 1
      end
   end

   return(t2)
end

-- ###################################################

local function processHost(hostname, host)
    local line
    local label = hostinfo2hostkey(host)

    -- starts is defined inside the lua_utils module
    if ((label == nil) or (string.len(label) == 0) or starts(label, "@")) then
        label = hostname
    end

    line = nil

    if (bubble_mode == HostsMapMode.ALL_FLOWS) then
        line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = host["active_flows.as_server"],
            y = host["active_flows.as_client"],
            z = host["bytes.sent"] + host["bytes.rcvd"]
        }
    elseif (bubble_mode == HostsMapMode.UNREACHABLE_FLOWS) then
        if (host["unreachable_flows.as_server"] + host["unreachable_flows.as_client"] > 0) then
            line = {
                meta = {
                    url_query = "host="..hostname,
                    label = label,
                },
                x = host["unreachable_flows.as_server"],
                y = host["unreachable_flows.as_client"],
                z = host["bytes.sent"] + host["bytes.rcvd"]
            }
        end
    elseif (bubble_mode == HostsMapMode.ALERTED_FLOWS) then
        if ((host["alerted_flows.as_server"] ~= nil) and
            (host["alerted_flows.as_client"] ~= nil) and
            (host["alerted_flows.as_server"] + host["alerted_flows.as_client"] > 0)) then
            line = {
                meta = {
                    url_query = "host="..hostname,
                    label = label,
                },
                x = host["alerted_flows.as_server"],
                y = host["alerted_flows.as_client"],
                z = host["alerted_flows.as_server"] + host["alerted_flows.as_client"]
            }
            -- if(label == "74.125.20.109") then tprint(line) end
        end
    elseif (bubble_mode == HostsMapMode.DNS_QUERIES) then

        if ((host["dns"] ~= nil) and
            ((host["dns"]["sent"]["num_queries"] + host["dns"]["rcvd"]["num_queries"]) > 0)) then

            local x = host["dns"]["rcvd"]["num_replies_ok"]
            local y = host["dns"]["sent"]["num_queries"]
            line = {
                meta = {
                    url_query = "host="..hostname,
                    label = label,
                }, 
                x = x, 
                y = y, 
                z = x + y
            }
        end
    elseif (bubble_mode == HostsMapMode.DNS_BYTES) then
       host = interface.getTrafficMapHostStats(hostname)
       if ((host ~= nil) and
	  (host["dns_traffic"] ~= nil) and
	  ((host["dns_traffic"]["sent"] + host["dns_traffic"]["rcvd"]) > 0)) then

            local x = host["dns_traffic"]["rcvd"]
            local y = host["dns_traffic"]["sent"]
            line = {
                meta = {
                    url_query = "host="..hostname,
                    label = label,
                }, 
                x = x, 
                y = y, 
                z = x + y
            }
        end
    elseif (bubble_mode == HostsMapMode.NTP_PACKETS) then
       host = interface.getTrafficMapHostStats(hostname)
       if ((host ~= nil) and
	  (host["ntp_traffic"] ~= nil) and
	  ((host["ntp_traffic"]["sent"] + host["ntp_traffic"]["rcvd"]) > 0)) then

            local x = host["ntp_traffic"]["rcvd"]
            local y = host["ntp_traffic"]["sent"]
            line = {
                meta = {
                    url_query = "host="..hostname,
                    label = label,
                }, 
                x = x, 
                y = y, 
                z = x + y
            }
        end
    elseif (bubble_mode == HostsMapMode.SYN_DISTRIBUTION) then

        local stats = interface.getHostInfo(host["ip"], host["vlan"])

        line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = stats["pktStats.sent"]["tcp_flags"]["syn"],
            y = stats["pktStats.recv"]["tcp_flags"]["syn"],
            z = host["active_flows.as_client"] + host["active_flows.as_server"]
        }
    elseif (bubble_mode == HostsMapMode.SYN_VS_RST) then
        
        local stats = interface.getHostInfo(host["ip"], host["vlan"])
        line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = stats["pktStats.sent"]["tcp_flags"]["syn"],
            y = stats["pktStats.recv"]["tcp_flags"]["rst"],
            z = host["active_flows.as_client"] + host["active_flows.as_server"]
        }
    elseif (bubble_mode == HostsMapMode.SYN_VS_SYNACK) then
        
        local stats = interface.getHostInfo(host["ip"], host["vlan"])
        line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = stats["pktStats.sent"]["tcp_flags"]["syn"],
            y = stats["pktStats.recv"]["tcp_flags"]["synack"],
            z = host["active_flows.as_client"] + host["active_flows.as_server"]
        }
    elseif (bubble_mode == HostsMapMode.TCP_PKTS_SENT_VS_RCVD) then
        
        local stats = interface.getHostInfo(host["ip"], host["vlan"])
        line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = stats["tcp.packets.sent"],
            y = stats["tcp.packets.rcvd"],
            z = stats["tcp.bytes.sent"] + stats["tcp.bytes.rcvd"]
        }
    elseif (bubble_mode == HostsMapMode.TCP_BYTES_SENT_VS_RCVD) then
        
        local stats = interface.getHostInfo(host["ip"], host["vlan"])

        line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = stats["tcp.bytes.sent"],
            y = stats["tcp.bytes.rcvd"],
            z = stats["tcp.bytes.sent"] + stats["tcp.bytes.rcvd"]
        }
       
    elseif (bubble_mode == HostsMapMode.ACTIVE_ALERT_FLOWS) then
        
        if (host["active_alerted_flows"] > 0) then
            line = {
                meta = {
                    url_query = "host="..hostname,
                    label = label,
                },
                x = host["active_flows.as_server"],
                y = host["active_flows.as_client"],
                z = host["active_alerted_flows"]
            }
        end
    elseif (bubble_mode == HostsMapMode.TRAFFIC_RATIO) then
       line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = host["bytes_ratio"],
            y = host["pkts_ratio"],
            z = host["bytes.sent"] + host["bytes.rcvd"]
       }
    elseif (bubble_mode == HostsMapMode.SCORE) then
       line = {
            meta = {
                url_query = "host="..hostname,
                label = label,
            },
            x = host["score.as_client"],
            y = host["score.as_server"],
            z = host["score.as_client"] + host["score.as_server"]
       }
    end

    if (line ~= nil) then        
        if (line.z > max_radius) then max_radius = line.z end

        if (host.localhost) then
            table.insert(local_hosts, line)
        else
            table.insert(remote_hosts, line)
        end
    end
end

if (show_remote) then
    callback_utils.foreachHost(ifname, processHost)
else
    callback_utils.foreachLocalHost(ifname, processHost)
end

-- Reduce the number of hosts to a reasonable value (< max_num)
local max_num = 999
local_hosts  = shrinkTable(local_hosts, max_num)
remote_hosts = shrinkTable(remote_hosts, max_num)

-- Normalize values
local ratio = max_radius / MAX_RADIUS_PX
for i,v in pairs(local_hosts) do 
    local_hosts[i].z = math.floor(MIN_RADIUS_PX + local_hosts[i].z / ratio) 
end

if (show_remote) then
    for i,v in pairs(remote_hosts) do 
        remote_hosts[i].z = math.floor(MIN_RADIUS_PX + remote_hosts[i].z / ratio) 
    end
end

local base_url = ntop.getHttpPrefix() .. "/lua/host_details.lua"

rest_utils.answer(rc, {
    series = {
        {data = local_hosts, name = "Local Hosts", base_url = base_url},
        {data = remote_hosts, name = "Remote Hosts", base_url = base_url},
    },
    grid = {
        padding = {
            left = 6
        },
    },
    colors = {"rgba(153, 102, 255, 0.45)", "rgba(255, 159, 64, 0.45)"},
    xaxis = {
        type = 'numeric',
        title = {
            text = MODES[bubble_mode + 1].x_label,
        },
        labels = {
            ntop_utils_formatter = MODES[bubble_mode + 1].x_formatter or 'none',
        }
    },
    yaxis = {
        type = 'numeric',
        title = {
            text = MODES[bubble_mode + 1].y_label,
            offsetX = 6
        },
        labels = {
            ntop_utils_formatter = MODES[bubble_mode + 1].y_formatter or 'none',
           
        }
    },
    dataLabels = {
        enabled = false
    },
})
