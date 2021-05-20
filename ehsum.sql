clear breaks
set lines 166 pages 500
col instance for a10
col event_name for a25 trunc
col wait_count for 999999999999
col wait_delta for 999999999
col cum_delta for 999999999
col tot_waits for 999999999
col pct_delta for 999.99
col pct_cum_delta for 999.99
col w_64s for 999999
col w_gt64s for 99999


with eh1 as (
select
        event_name
	, e.instance_number inst
	, to_char(begin_interval_time, 'yyyy/mm/dd') sday
        , WAIT_TIME_MILLI
        , wait_count - lag(wait_count) over(partition by e.event_name, e.instance_number, wait_time_milli order by e.snap_id) wait_delta
from DBA_HIST_EVENT_HISTOGRAM e, dba_hist_snapshot h
where lower(event_name) like lower('&1')
  and e.snap_id = h.snap_id
  and e.dbid = h.dbid
  and e.instance_number = h.instance_number
  and h.begin_interval_time >= trunc(sysdate) - 30
),
eh2 as(
select event_name
	, name || inst instance
        , sday
        , WAIT_TIME_MILLI
        , sum(wait_delta) waits
from eh1, v$database d
where wait_delta > 0
group by event_name
        , d.name || inst
        , sday
        , WAIT_TIME_MILLI
)
select event_name
	, sday
	, instance
        , sum(case when wait_time_milli <= 2 then waits else 0 end) w_2ms
        , sum(case when wait_time_milli in (4,8) then waits else 0 end) w_8ms
        , sum(case when wait_time_milli in (16,32) then waits else 0 end) w_32ms
        , sum(case when wait_time_milli in (64,128) then waits else 0 end) w_128ms
        , sum(case when wait_time_milli in (256,512) then waits else 0 end) w_512ms
        , sum(case when wait_time_milli in (2048, 1024) then waits else 0 end) w_2s
        , sum(case when wait_time_milli in (4096,8192) then waits else 0 end) w_8s
        , sum(case when wait_time_milli = 16384 then waits else 0 end) w_16s
        , sum(case when wait_time_milli = 32768 then waits else 0 end) w_32s
        , sum(case when wait_time_milli = 65536 then waits else 0 end) w_64s
        , sum(case when wait_time_milli > 65536 then waits else 0 end) w_gt64s
from eh2
group by event_name
        , sday
        , instance
order by event_name, sday, instance
/

