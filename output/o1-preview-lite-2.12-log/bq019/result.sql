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
  ORDER BY city_total_discharges DESC
  LIMIT 3
),
weighted_payments AS (
  SELECT
    (SELECT drg_definition FROM top_drg) AS DRG_definition,
    provider_city AS City,
    ROUND(SUM(total_discharges * average_total_payments) / SUM(total_discharges), 4) AS Weighted_Average_Total_Payments
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
  WHERE drg_definition = (SELECT drg_definition FROM top_drg)
    AND provider_city IN (SELECT provider_city FROM city_totals)
  GROUP BY provider_city
)
SELECT DRG_definition, City, Weighted_Average_Total_Payments
FROM weighted_payments
ORDER BY Weighted_Average_Total_Payments DESC;