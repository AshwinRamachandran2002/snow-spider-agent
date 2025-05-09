WITH all_events AS (
  SELECT event_name, event_timestamp, user_pseudo_id FROM (
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180801` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180802` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180803` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180804` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180805` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180806` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180807` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180808` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180809` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180810` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180811` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180812` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180813` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180814` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180815` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180816` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180817` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180818` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180819` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180820` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180821` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180822` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180823` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180824` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180825` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180826` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180827` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180828` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180829` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180830` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180831` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180901` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180902` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180903` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180904` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180905` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180906` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180907` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180908` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180909` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180910` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180911` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180912` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180913` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180914` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180915` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180916` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180917` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180918` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180919` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180920` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180921` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180922` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180923` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180924` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180925` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180926` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180927` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180928` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180929` UNION ALL
    SELECT event_name, event_timestamp, user_pseudo_id FROM `firebase-public-project.analytics_153293282.events_20180930`
  )
  WHERE event_name IN ('first_open', 'app_remove')
),
installs AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_open_ts
  FROM all_events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),
uninstalls AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS uninstall_ts
  FROM all_events
  WHERE event_name = 'app_remove'
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
      SUM(
        CASE
          WHEN uninstalls.uninstall_ts IS NULL
               OR uninstalls.uninstall_ts > installs.first_open_ts + 604800000000
          THEN 1
          ELSE 0
        END
      ),
      COUNT(*)
    ),
    4
  ) AS retention_percentage
FROM installs
LEFT JOIN uninstalls USING (user_pseudo_id);