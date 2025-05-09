WITH
-- 1. pick the first page (landing) of each session
landing AS (
  SELECT  a.session,
          a.path
  FROM    activity_log AS a
  JOIN   (SELECT session, MIN(stamp) AS min_stamp
          FROM   activity_log
          GROUP  BY session) AS m
    ON a.session = m.session
   AND a.stamp   = m.min_stamp
),
-- 2. pick the last page (exit) of each session
exit AS (
  SELECT  a.session,
          a.path
  FROM    activity_log AS a
  JOIN   (SELECT session, MAX(stamp) AS max_stamp
          FROM   activity_log
          GROUP  BY session) AS m
    ON a.session = m.session
   AND a.stamp   = m.max_stamp
),
-- 3. keep one record per (session, path) even if the page is both landing & exit
landing_exit AS (
  SELECT session, path FROM landing
  UNION
  SELECT session, path FROM exit
)
-- 4. count distinct sessions for every page
SELECT   path,
         COUNT(DISTINCT session) AS unique_session_cnt
FROM     landing_exit
GROUP BY path
ORDER BY unique_session_cnt DESC;