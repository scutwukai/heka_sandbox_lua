--[[
:Timestamp: 2015-09-09 03:15:49 +0000 UTC
:Type: mysql.slow-query
:Hostname: app1.gamesales3
:Pid: 0
:Uuid: 87303593-3a61-4a6f-ab87-675cae0b0533
:Logger: slow_input
:Payload: SELECT * FROM seo WHERE url = '/app/acct/17/104' LIMIT 0, 1;
:EnvVersion:
:Severity: 7
:Fields:
    | name:"Rows_examined" type:double value:21
    | name:"Query_time" type:double value:0.000146 representation:"s"
    | name:"Rows_sent" type:double value:1
    | name:"Lock_time" type:double value:4.3e-05 representation:"s"
]]--

--require "math"
--require "string"

require "os"

local INT    = 2
local DOUBLE = 3

local startup = os.time() * 1e9
local ready = false

local count = 0
local sum_query_time = 0.0     -- micro second


function process_message ()
    if not ready and read_message("Timestamp") < startup then
        return 0
    else
        ready = true
    end

    local query = read_message("Fields[Query_time]")

    count = count + 1
    sum_query_time = sum_query_time + (query * 1000)

    return 0
end

function timer_event(ns)
    if not ready then
        return
    end

    local avg_query_time = 0
    if count > 0 then
        avg_query_time = sum_query_time / count
    end

    local msg = {
        Type = "mysql.slow-query.stat",
        Payload = "",
        Fields = {
            {name="mysql_slow_count",      value=count,          value_type=INT,    representation="ts"},
            {name="mysql_slow_avg_query",  value=avg_query_time, value_type=DOUBLE, representation="ms"}
        }
    }

    inject_message(msg)

    count = 0
    sum_query_time = 0.0
end
