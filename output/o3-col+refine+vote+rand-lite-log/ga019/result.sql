/* Percentage of August-September 2018 installers who either
   never uninstalled or waited more than 7 days to uninstall */
SELECT
  ROUND(
        100.0 * SUM(
                     CASE
                       WHEN uninstall_ts IS NULL
                            OR (uninstall_ts - install_ts) > 7*24*60*60*1e6
                       THEN 1
                       ELSE 0
                     END
                   ) / COUNT(*)
       , 2) AS pct_retained_or_long_uninstall
FROM (
  /* join first installs with first uninstalls */
  SELECT
    i.user_pseudo_id,
    i.install_ts,
    u.uninstall_ts
  FROM (
      /* first install per user */
      SELECT
        user_pseudo_id,
        MIN(event_timestamp) AS install_ts
      FROM `firebase-public-project.analytics_153293282.events_*`
      WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
        AND event_name = 'first_open'
      GROUP BY user_pseudo_id
  ) AS i
  LEFT JOIN (
      /* first uninstall per user (if any) */
      SELECT
        user_pseudo_id,
        MIN(event_timestamp) AS uninstall_ts
      FROM `firebase-public-project.analytics_153293282.events_*`
      WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
        AND event_name = 'app_remove'
      GROUP BY user_pseudo_id
  ) AS u
  USING (user_pseudo_id)
);