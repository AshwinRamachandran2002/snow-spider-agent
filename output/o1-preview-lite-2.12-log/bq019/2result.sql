WITH drg_totals AS (
  SELECT drg_definition, SUM(total_discharges) AS total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  GROUP BY drg_definition
),
top_drg AS (
  SELECT drg_definition
  FROM drg_totals
  ORDER BY total_discharges DESC
  LIMIT 1
),
city_totals AS (
  SELECT provider_city, SUM(total_discharges) AS city_total_discharges
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM top_drg)
  GROUP BY provider_city
),
top_cities AS (
  SELECT provider_city
  FROM city_totals
  ORDER BY city_total_discharges DESC
  LIMIT 3
)
SELECT
  (SELECT drg_definition FROM top_drg) AS DRG_definition,
  provider_city AS City,
  ROUND(SUM(average_total_payments * total_discharges) / SUM(total_discharges), 4) AS Weighted_Average_Total_Payments
FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
WHERE drg_definition = (SELECT drg_definition FROM top_drg)
  AND provider_city IN (SELECT provider_city FROM top_cities)
GROUP BY provider_city
ORDER BY Weighted_Average_Total_Payments DESC;