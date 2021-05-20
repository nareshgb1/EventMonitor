col event for a35 trunc
col wait_sec for 999,999,999.99
set lines 166
select * from (
select inst_id, event, WAIT_TIME_MILLI, wait_time_milli/1000 wait_sec, wait_count, last_update_time 
from gv$event_histogram where lower(event) like lower('&1')
--  and wait_time_milli > 64
  and wait_count >0
  and to_date(substr(last_update_time, 1, 9), 'DD-MON-YY') > sysdate - 1
order by 1,2,3 desc
) where rownum < 10
/
