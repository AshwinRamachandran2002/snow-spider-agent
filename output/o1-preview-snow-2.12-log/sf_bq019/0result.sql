WITH drg_totals AS (
  SELECT
    "drg_definition",
    SUM("total_discharges") AS "total_discharges"
  FROM
    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
  GROUP BY
    "drg_definition"
  ORDER BY
    "total_discharges" DESC NULLS LAST
  LIMIT 1
),
top_cities AS (
  SELECT
    "provider_city" AS "City",
    SUM("total_discharges") AS "Total_Discharges",
    SUM("average_total_payments" * "total_discharges") / SUM("total_discharges") AS "Weighted_Average_Total_Payments"
  FROM
    CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
  WHERE
    "drg_definition" = (SELECT "drg_definition" FROM drg_totals)
  GROUP BY
    "provider_city"
  ORDER BY
    "Total_Discharges" DESC NULLS LAST
  LIMIT 3
)
SELECT
  (SELECT "drg_definition" FROM drg_totals) AS "DRG_Definition",
  "City",
  ROUND("Weighted_Average_Total_Payments", 4) AS "Weighted_Average_Total_Payments"
FROM
  top_cities;