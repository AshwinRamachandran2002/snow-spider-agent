WITH top_drg AS (                         -- 1) DRG with the most 2014 discharges
  SELECT
    drg_definition
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
  ORDER BY SUM(total_discharges) DESC
  LIMIT 1
),
city_stats AS (                           -- 2) Per-city metrics for that DRG
  SELECT
    provider_city,
    SUM(total_discharges)                                   AS city_total_discharges,
    ROUND(                                                  -- weight = total_discharges
      SUM(average_total_payments * total_discharges) /
      SUM(total_discharges), 4)                             AS weighted_avg_total_payment
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM top_drg)
  GROUP BY provider_city
)
SELECT                                     -- 3) Top-3 cities by discharge volume
  (SELECT drg_definition FROM top_drg) AS drg_definition,
  provider_city,
  city_total_discharges,
  weighted_avg_total_payment
FROM city_stats
ORDER BY city_total_discharges DESC
LIMIT 3;