set lines 166
col event_name for a30 trunc
--break on event_name skip 1 on snap_id on snap_int
col waits_sec for 999999.9
col av_wait_ms for 999999.9
col snap_int for a25
col inst for 99
col instance for a10 
col host for a10 trunc
 
with min_snap as (select min( snap_id) snap1
from dba_hist_snapshot where (sysdate - 5/24) between begin_interval_time and end_interval_time
)
select 
	instance, host, event_name
	, snap_id
	, snap_int
	, waits_delta
	, waits_Sec
	, decode(waits_delta, 0, 0, waits_sec*1000/waits_delta) av_wait_ms
from (
select i.instance_name instance, i.host_name host,
	s1.event_name, s1.snap_id, s1.instance_number inst,
        to_char(h.begin_interval_time, 'dd-mon-yy hh24:mi') || ' to ' || to_char(h.end_interval_time,  'hh24:mi') snap_int,
        lag(total_waits) over(order by s1.snap_id) prev_waits,
        total_waits - lag(total_waits) over(partition by event_name, s1.instance_number order by s1.snap_id) as waits_delta,
        (TIME_WAITED_MICRO - lag(TIME_WAITED_MICRO) over(partition by event_name, s1.instance_number order by s1.snap_id))/1000000 as waits_sec
from dba_hist_system_event s1, dba_hist_snapshot h, gv$instance i
where h.snap_id > (select distinct snap1 from min_snap)
  and h.begin_interval_time < sysdate + 1/2 
  and h.snap_id = s1.snap_id 
  and h.instance_number = s1.instance_number
  and lower(s1.event_name) like lower('&1') || '%'
  and h.instance_number = i.inst_id
  and h.dbid = s1.dbid
) where prev_waits is not null and waits_delta is not null
order by event_name
	, snap_id, inst
/
