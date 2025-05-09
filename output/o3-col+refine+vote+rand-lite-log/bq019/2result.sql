WITH top_drg AS (
  -- 1) Identify the DRG definition with the highest total discharges in 2014
  SELECT drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
city_stats AS (
  -- 2) For that DRG, compute city-level totals and weighted-average payments
  SELECT
    provider_city,
    SUM(total_discharges)                                         AS city_total_discharges,
    SUM(average_total_payments * total_discharges)
/   SUM(total_discharges)                                          AS weighted_avg_total_payment
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM top_drg)
  GROUP BY provider_city
)
-- 3) Return the top 3 cities (by discharges) with their weighted averages
SELECT
  (SELECT drg_definition FROM top_drg)        AS top_drg_definition,
  provider_city,
  city_total_discharges,
  ROUND(weighted_avg_total_payment, 4)        AS weighted_avg_total_payment
FROM city_stats
ORDER BY city_total_discharges DESC
LIMIT 3;