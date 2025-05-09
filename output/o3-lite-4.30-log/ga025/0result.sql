WITH events AS (
    SELECT user_pseudo_id,
           event_name,
           event_timestamp,
           DATE(TIMESTAMP_MICROS(event_timestamp)) AS evt_date
    FROM `firebase-public-project.analytics_153293282.events_20180901` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180902` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180903` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180904` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180905` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180906` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180907` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180908` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180909` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180910` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180911` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180912` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180913` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180914` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180915` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180916` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180917` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180918` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180919` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180920` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180921` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180922` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180923` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180924` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180925` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180926` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180927` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180928` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180929` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp)) 
    FROM `firebase-public-project.analytics_153293282.events_20180930` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp))
    FROM `firebase-public-project.analytics_153293282.events_20181001` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp))
    FROM `firebase-public-project.analytics_153293282.events_20181002` UNION ALL
    SELECT user_pseudo_id, event_name, event_timestamp, DATE(TIMESTAMP_MICROS(event_timestamp))
    FROM `firebase-public-project.analytics_153293282.events_20181003`
),
first_open AS (
    SELECT user_pseudo_id,
           MIN(evt_date) AS open_date
    FROM events
    WHERE event_name = 'first_open'
      AND evt_date BETWEEN DATE '2018-09-01' AND DATE '2018-09-30'
    GROUP BY user_pseudo_id
),
fast_uninstalls AS (
    SELECT DISTINCT
           o.user_pseudo_id,
           o.open_date,
           r.evt_date AS remove_date
    FROM first_open o
    JOIN events    r
      ON r.user_pseudo_id = o.user_pseudo_id
     AND r.event_name   = 'app_remove'
     AND DATE_DIFF(r.evt_date, o.open_date, DAY) BETWEEN 0 AND 7
),
crashes AS (
    SELECT DISTINCT
           f.user_pseudo_id
    FROM fast_uninstalls f
    JOIN events e
      ON e.user_pseudo_id = f.user_pseudo_id
     AND e.event_name     = 'app_exception'
     AND e.evt_date BETWEEN f.open_date AND f.remove_date
)
SELECT
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT crashes.user_pseudo_id),
                      COUNT(DISTINCT fast_uninstalls.user_pseudo_id)) * 100, 4)
           AS crash_percentage_within_7d
FROM fast_uninstalls
LEFT JOIN crashes USING (user_pseudo_id);