WITH dedup AS (
  SELECT DISTINCT
         `fullVisitorId`,
         `visitId`,
         `channelGrouping`,
         `geoNetwork_country`            AS country,
         `totals_transactions`
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE `totals_transactions` IS NOT NULL
),
tx_by_country AS (
  SELECT
         `channelGrouping`,
         country,
         SUM(`totals_transactions`)      AS total_transactions
  FROM dedup
  GROUP BY `channelGrouping`, country
),
ranked AS (
  SELECT
         `channelGrouping`,
         country,
         total_transactions,
         ROW_NUMBER() OVER (PARTITION BY `channelGrouping`
                            ORDER BY total_transactions DESC, country) AS rn,
         COUNT(*)    OVER (PARTITION BY `channelGrouping`)             AS country_cnt
  FROM tx_by_country
)
SELECT
       `channelGrouping` AS channel_grouping,
       country           AS top_country,
       total_transactions
FROM ranked
WHERE country_cnt > 1
  AND rn = 1
ORDER BY channel_grouping;