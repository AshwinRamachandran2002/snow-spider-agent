/* Find, for every channelGrouping that has transactions coming from
   more than one country, the country that contributes the most
   transactions (after removing duplicate transaction‑level rows).      */

WITH unique_visits AS (   -- 1 row per (visitor, visit)
  SELECT
    fullVisitorId,
    visitId,
    channelGrouping,
    geoNetwork_country            AS country,
    MAX(totals_transactions)      AS transactions    -- transactions for that visit
  FROM `data-to-insights.ecommerce.rev_transactions`
  GROUP BY
    fullVisitorId,
    visitId,
    channelGrouping,
    country
),

channel_country AS (      -- aggregate to channel‑country level
  SELECT
    channelGrouping,
    country,
    SUM(transactions)      AS total_transactions
  FROM unique_visits
  GROUP BY
    channelGrouping,
    country
),

eligible_channels AS (    -- keep channel groupings with >1 country
  SELECT
    channelGrouping
  FROM channel_country
  WHERE total_transactions > 0
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
)

SELECT
  cc.channelGrouping,
  cc.country,
  cc.total_transactions
FROM channel_country AS cc
JOIN eligible_channels AS ec
  ON cc.channelGrouping = ec.channelGrouping
QUALIFY
  ROW_NUMBER() OVER (PARTITION BY cc.channelGrouping
                     ORDER BY cc.total_transactions DESC, cc.country) = 1
ORDER BY
  channelGrouping;