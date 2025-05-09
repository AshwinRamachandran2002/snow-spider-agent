-- % of new users (Aug‑01‑2016 – Apr‑30‑2017) whose first session
-- lasted > 5 min and who completed a purchase in any later session
WITH all_sessions AS (
  SELECT
    _TABLE_SUFFIX            AS session_date ,          -- yyyymmdd
    fullVisitorId,
    visitStartTime,                                   -- epoch seconds
    totals.newVisits        AS newVisits,
    totals.timeOnSite       AS timeOnSite,            -- seconds
    totals.transactions     AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  -- keep all sessions we might need (initial‑visit window + later purchases)
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
),

-- first (new‑visit) session for every user inside the required window
initial_sessions AS (
  SELECT
    fullVisitorId,
    ( ARRAY_AGG(STRUCT(visitStartTime, timeOnSite)
                ORDER BY visitStartTime
                LIMIT 1) )[OFFSET(0)]                     AS init   -- STRUCT
  FROM all_sessions
  WHERE newVisits = 1
    AND session_date BETWEEN '20160801' AND '20170430'
  GROUP BY fullVisitorId
),

-- users who bought in any session AFTER that initial visit
purchasers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM all_sessions      AS s
  JOIN initial_sessions  AS i
    ON s.fullVisitorId = i.fullVisitorId
  WHERE s.visitStartTime > i.init.visitStartTime       -- later session
    AND s.transactions   >= 1                          -- made a purchase
),

-- combine the two conditions for every new user
user_flags AS (
  SELECT
    i.fullVisitorId,
    i.init.timeOnSite                                   AS initial_time_on_site,
    (i.init.timeOnSite > 300)                           AS long_initial_visit,
    (p.fullVisitorId IS NOT NULL)                       AS purchased_later
  FROM initial_sessions i
  LEFT JOIN purchasers p
    ON i.fullVisitorId = p.fullVisitorId
)

-- final percentage
SELECT
  COUNTIF(long_initial_visit AND purchased_later) * 100.0
  / COUNT(*)                                           AS percentage_of_new_users
FROM user_flags;