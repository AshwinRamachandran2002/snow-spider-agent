-- Percentage of August‑September‑2018 installers who did NOT uninstall
-- within seven days of their installation (i.e. either uninstalled
-- after 7 days or have never sent an `app_remove` event).

WITH first_open AS (      -- installation cohort (Aug & Sep 2018)
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS install_ts          -- earliest install in period
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

app_remove AS (           -- first uninstall within seven days, if any
  SELECT
    e.user_pseudo_id,
    MIN(e.event_timestamp) AS remove_ts
  FROM `firebase-public-project.analytics_153293282.events_*`  e
  JOIN first_open f
    ON e.user_pseudo_id = f.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20181003'        -- include later days
    AND e.event_name = 'app_remove'
    AND e.event_timestamp BETWEEN f.install_ts
                               AND f.install_ts + 7*24*60*60*1000000  -- 7 days (µs)
  GROUP BY e.user_pseudo_id
),

classification AS (
  SELECT
    f.user_pseudo_id,
    CASE WHEN a.remove_ts IS NULL THEN 1 ELSE 0 END AS stayed_7_plus
  FROM first_open f
  LEFT JOIN app_remove a
    ON f.user_pseudo_id = a.user_pseudo_id
)

SELECT
  ROUND( SAFE_DIVIDE( COUNTIF(stayed_7_plus = 1) , COUNT(*) ) * 100 , 4)
    AS pct_users_not_uninstalled_within_7_days
FROM classification;