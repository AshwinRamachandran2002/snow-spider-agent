/* Percentage of new users (Aug‑01‑2016 – Apr‑30‑2017) who
   1) spent more than five minutes ( >300 s) on their first session and
   2) completed at least one transaction on a later session. */

WITH initial_sessions AS (        -- first visit of each “new user” in the period
  SELECT
    fullVisitorId,
    visitStartTime           AS init_visitStartTime,
    totals.timeOnSite        AS init_timeOnSite
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'   -- Aug‑01‑2016 … Apr‑30‑2017
    AND totals.newVisits = 1
),

subsequent_purchasers AS (        -- those same users who bought on a later visit
  SELECT DISTINCT i.fullVisitorId
  FROM   initial_sessions AS i
  JOIN   `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
         ON  s.fullVisitorId = i.fullVisitorId
  WHERE  s._TABLE_SUFFIX BETWEEN '20160801' AND '20170801'           -- whole demo range
         AND s.visitStartTime > i.init_visitStartTime                -- later visit
         AND s.totals.transactions >= 1                              -- made a purchase
),

totals AS (                       -- total new users in the period
  SELECT COUNT(DISTINCT fullVisitorId) AS total_new_users
  FROM   initial_sessions
),

qualified AS (                    -- new users who meet both conditions
  SELECT COUNT(DISTINCT i.fullVisitorId) AS qualified_users
  FROM   initial_sessions AS i
  JOIN   subsequent_purchasers AS p
         ON p.fullVisitorId = i.fullVisitorId
  WHERE  i.init_timeOnSite > 300                                      -- > 5 minutes
)

SELECT
  qualified_users,
  total_new_users,
  ROUND(qualified_users / total_new_users * 100, 4) AS percentage_new_users
FROM qualified
CROSS JOIN totals;