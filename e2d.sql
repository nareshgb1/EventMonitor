clear breaks
col event_name for a30 trunc
set lines 166
col waits_sec for 999999.9
col h_day for a10
col av_wait_ms for 999999.9
col snap_st for a5
col instance_name for a10 head instance
col host_name for a15 trunc head host


select 
	instance_name, host_name, 
	event_name
	, h_day
	, snap_st
	, snap_id
	, inst
	, waits_delta
	, waits_Sec
	, decode(waits_delta, 0, 0, waits_sec*1000/waits_delta) av_wait_ms
from (
select i.instance_name, i.host_name, s1.event_name, s1.snap_id, s1.instance_number inst,
        to_char(h.begin_interval_time, 'yyyy/mm/dd' ) h_day, to_char(begin_interval_time, 'hh24:mi') snap_st,
        lag(total_waits) over(partition by event_name, s1.instance_number, h.startup_time order by s1.snap_id) as prev_waits,
        total_waits - lag(total_waits) over(partition by event_name, s1.instance_number, h.startup_time order by s1.snap_id) as waits_delta,
        (TIME_WAITED_MICRO - lag(TIME_WAITED_MICRO) over(partition by event_name, s1.instance_number, h.startup_time order by s1.snap_id))/1000000 as waits_sec
from dba_hist_system_event s1, dba_hist_snapshot h, dba_hist_database_instance i
where h.begin_interval_time >= trunc(sysdate) - 1.1/24
  and lower(s1.event_name) like lower('&1') || '%'
  and h.snap_id = s1.snap_id 
  and h.instance_number = s1.instance_number
  and h.instance_number = i.instance_number
  and h.dbid = i.dbid and h.startup_time = i.startup_time
) where prev_waits is not null
order by event_name
	, snap_id
/
