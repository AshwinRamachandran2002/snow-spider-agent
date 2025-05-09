WITH drg_totals AS (
  SELECT "drg_definition"
  FROM (
    SELECT "drg_definition", SUM("total_discharges") AS "total_discharges"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "drg_definition"
    ORDER BY "total_discharges" DESC NULLS LAST
    LIMIT 1
  )
),
top_cities AS (
  SELECT "provider_city", SUM("total_discharges") AS "city_total_discharges"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
  WHERE "drg_definition" = (SELECT "drg_definition" FROM drg_totals)
  GROUP BY "provider_city"
  ORDER BY "city_total_discharges" DESC NULLS LAST
  LIMIT 3
),
city_payments AS (
  SELECT 
    "provider_city",
    ROUND(SUM("average_total_payments" * "total_discharges") / SUM("total_discharges"), 4) AS "Weighted_Average_Total_Payments"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
  WHERE "drg_definition" = (SELECT "drg_definition" FROM drg_totals)
    AND "provider_city" IN (SELECT "provider_city" FROM top_cities)
  GROUP BY "provider_city"
)
SELECT 
  (SELECT "drg_definition" FROM drg_totals) AS "DRG_Definition",
  "provider_city" AS "City",
  "Weighted_Average_Total_Payments"
FROM city_payments
ORDER BY "Weighted_Average_Total_Payments" DESC NULLS LAST;