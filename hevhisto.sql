clear breaks
set lines 166 pages 500
col event_name for a25 trunc
col wait_count for 999999999999
col wait_delta for 999999999
col cum_delta for 999999999
col tot_waits for 999999999
col pct_delta for 999.99
col pct_cum_delta for 999.99


with eh1 as (
select
        event_name
	, instance_number inst
        , snap_id
        , WAIT_TIME_MILLI
        , WAIT_COUNT
        , wait_count - lag(wait_count) over(partition by event_name, instance_number, wait_time_milli order by snap_id) wait_delta
from DBA_HIST_EVENT_HISTOGRAM
where snap_id between &1 - 1 and &2 and event_name like '&3%'
),
eh2 as(
select event_name
	, inst
        , snap_id
        , WAIT_TIME_MILLI
        , wait_count
        , wait_delta
        , sum(wait_delta) over(partition by inst, snap_id order by WAIT_TIME_MILLI) cum_delta
        , sum(wait_delta) over(partition by inst, snap_id) tot_waits
from eh1
)
select event_name
        , s.snap_id
	, inst
	, to_char(begin_interval_time, 'yyyy/mm/dd') h_day
	, to_char(begin_interval_time, 'hh24:mi') h_min
        , WAIT_TIME_MILLI
        , wait_count
        , wait_delta
        , cum_delta
        , tot_waits
        , 100*wait_delta/tot_waits pct_delta
        , 100*cum_delta/tot_waits pct_cum_delta
from eh2, dba_hist_snapshot s
where eh2.snap_id = s.snap_id
  and eh2.inst = s.instance_number
  and wait_delta > 0
order by event_name, s.snap_id, inst, WAIT_TIME_MILLI
/

