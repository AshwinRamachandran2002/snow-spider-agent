-- DRG with the most total discharges in 2014 and
-- the weighted‑average total payments for the three cities
-- that account for the largest number of those discharges
WITH drg_rank AS (      -- rank DRGs by total discharges
  SELECT
    drg_definition,
    SUM(total_discharges) AS drg_total_discharges,
    ROW_NUMBER() OVER (ORDER BY SUM(total_discharges) DESC) AS rn
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
),
top_drg AS (            -- keep only the #1 DRG
  SELECT drg_definition
  FROM drg_rank
  WHERE rn = 1
),
city_aggregation AS (   -- city‑level stats for the top DRG
  SELECT
    provider_city                    AS city,
    SUM(total_discharges)           AS city_total_discharges,
    SUM(average_total_payments * total_discharges)
/ SUM(total_discharges)            AS weighted_avg_total_payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition IN (SELECT drg_definition FROM top_drg)
  GROUP BY city
),
top_cities AS (         -- three cities with the most discharges
  SELECT *
  FROM city_aggregation
  ORDER BY city_total_discharges DESC, city
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM top_drg)               AS drg_definition_with_most_discharges,
  city,
  city_total_discharges,
  weighted_avg_total_payments
FROM top_cities
ORDER BY city_total_discharges DESC, city;