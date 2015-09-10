--[[
:Timestamp: 2015-09-08 03:21:09 +0000 UTC
:Type: nginx.access
:Hostname: gsdev
:Pid: 0
:Uuid: 60a57596-fbaf-49e4-af2b-ec53224895cb
:Logger: nginx_access_input
:Payload:
:EnvVersion:
:Severity: 7
:Fields:
    | name:"user_agent_browser" type:string value:"Firefox"
    | name:"cookie_sid" type:string value:"TqweuNGI1uYUWlSWHNBOivMC4R5wwJY0sfVcdxNP"
    | name:"user_agent_version" type:double value:40
    | name:"upstream_response_time" type:double value:0.005 representation:"s"
    | name:"remote_user" type:string value:"-"
    | name:"http_x_forwarded_for" type:string value:"-"
    | name:"http_referer" type:string value:"http://gs3.wk.dev.webapp.163.com:8201/404.html"
    | name:"body_bytes_sent" type:double value:375 representation:"B"
    | name:"remote_addr" type:string value:"10.120.173.207" representation:"ipv4"
    | name:"user_agent_os" type:string value:"Macintosh"
    | name:"request" type:string value:"GET /app/center HTTP/1.1"
    | name:"status" type:double value:302
    | name:"uri" type:string value:"/app/center"
    | name:"request_time" type:double value:0.005 representation:"s"
]]--

require "os"
require "math"
require "string"

local startup = os.time() * 1e9
local ready = false

local total = 0
local n50x = 0

local up = 0
local sum_uptime = 0            -- ms


function process_message ()
    if not ready and read_message("Timestamp") < startup then
        return 0
    else
        ready = true
    end

    local status = read_message("Fields[status]")
    local uptime = read_message("Fields[upstream_response_time]")

    total = total + 1

    if uptime > 0 then
        up = up + 1
        sum_uptime = sum_uptime + uptime * 1000
    end

    --if status >= 500 and status < 600 then
    if status == 302 then
        n50x = n50x + 1
    end

    return 0
end

function timer_event(ns)
    if not ready then
        return
    end

    local avg_uptime = 0
    if up > 0 then
        avg_uptime = math.ceil(sum_uptime / up)
    end

    local msg = {
        Type = "nginx.access.stat",
        Payload = "",
        Fields = {
            {name="nginx_all",         value=total,      value_type=2, representation="ts"},
            {name="nginx_50x",         value=n50x,       value_type=2, representation="ts"},
            {name="nginx_avg_uptime",  value=avg_uptime, value_type=2, representation="ms"}
        }
    }

    inject_message(msg)

    total = 0
    n50x = 0

    up = 0
    sum_uptime = 0
end
