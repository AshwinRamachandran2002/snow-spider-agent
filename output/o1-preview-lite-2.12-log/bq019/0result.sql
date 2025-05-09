WITH top_drg AS (
  SELECT drg_definition
  FROM (
    SELECT drg_definition, SUM(total_discharges) AS total_discharges
    FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014`
    GROUP BY drg_definition
    ORDER BY total_discharges DESC
    LIMIT 1
  )
),
top_cities AS (
  SELECT provider_city
  FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS t
  JOIN top_drg
    ON t.drg_definition = top_drg.drg_definition
  GROUP BY provider_city
  ORDER BY SUM(t.total_discharges) DESC
  LIMIT 3
)
SELECT
  t.drg_definition AS DRG_definition,
  t.provider_city AS City,
  ROUND(SUM(t.average_total_payments * t.total_discharges) / SUM(t.total_discharges), 4) AS Weighted_Average_Total_Payments
FROM `bigquery-public-data.cms_medicare.inpatient_charges_2014` AS t
JOIN top_drg
  ON t.drg_definition = top_drg.drg_definition
JOIN top_cities
  ON t.provider_city = top_cities.provider_city
GROUP BY t.drg_definition, t.provider_city