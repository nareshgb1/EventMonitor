set lines 166
col dbname for a10
col dow for a3
col sec for 999999999.99
col max_sec for 999999999
col waits for 99999999999999
col av_ms for 999999.99
col max_ms for 999999.99
col sday for a10
col m_waits for 99999999 
col k_sec for 99999 
col event_name for a35 trunc
col maxsnap for 999999
col minsnap for 999999
col timeouts for 9999999
clear breaks

prompt Daily SUmmary for &1

select dbname, sday, dow, event_name,
	min(e.snap_id) minsnap, max(e.snap_id) maxsnap, sum(waits) waits,
	sum(timeouts) timeouts, sum(usec/1000000) sec, max(usec/1000000) max_sec,
	case when sum(waits) > 0 then sum(usec/1000)/sum(waits) else 0 end av_ms,
	max((usec/1000)/waits) max_ms, sum(waits)/1000000 m_waits
	--, sum(usec/1000000/1000) k_sec
from
	(select e.snap_id,
		to_char(begin_interval_time, 'yyyy/mm/dd') sday,
		upper(substr(to_char(begin_interval_time, 'day'), 1,3)) dow,
		event_name, i.db_name dbname, e.instance_number,
		total_waits - lag(total_waits) over(partition by event_name, e.instance_number, h.startup_time order by e.snap_id) waits,
		total_timeouts - lag(total_timeouts) over(partition by event_name, e.instance_number, h.startup_time order by e.snap_id) timeouts,
		time_waited_micro - lag(time_waited_micro) over(partition by event_name, e.instance_number, h.startup_time order by e.snap_id) usec
	from dba_hist_system_event e, dba_hist_snapshot h, dba_hist_database_instance i
	where lower(event_name) like lower('&1')
	  and e.snap_id = h.snap_id
	  and e.instance_number = h.instance_number
	  and h.begin_interval_time > sysdate - 31
  	  and e.dbid = h.dbid and h.snap_flag = 0
	  and h.dbid = i.dbid and h.instance_number = i.instance_number and h.startup_time  = i.startup_time
	) e
where waits >  0 and usec >= 0
group by dbname , event_name, sday, dow
order by 1
/
