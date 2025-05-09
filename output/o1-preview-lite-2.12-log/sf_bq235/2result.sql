WITH inpatient_totals AS (
  SELECT "provider_id", "provider_name",
         SUM("total_discharges" * "average_total_payments") AS total_inpatient_payments,
         SUM("total_discharges") AS total_inpatient_services
  FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
  GROUP BY "provider_id", "provider_name"
),
outpatient_totals AS (
  SELECT "provider_id",
         SUM("outpatient_services" * "average_total_payments") AS total_outpatient_payments,
         SUM("outpatient_services") AS total_outpatient_services
  FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2014"
  GROUP BY "provider_id"
),
combined_totals AS (
  SELECT COALESCE(it."provider_id", ot."provider_id") AS "provider_id",
         COALESCE(it."provider_name", '') AS "provider_name",
         COALESCE(it.total_inpatient_payments, 0) + COALESCE(ot.total_outpatient_payments, 0) AS combined_total_payments,
         COALESCE(it.total_inpatient_services, 0) + COALESCE(ot.total_outpatient_services, 0) AS combined_total_services,
         ROUND((COALESCE(it.total_inpatient_payments, 0) + COALESCE(ot.total_outpatient_payments, 0)) / NULLIF((COALESCE(it.total_inpatient_services, 0) + COALESCE(ot.total_outpatient_services, 0)), 0), 4) AS combined_average_cost
  FROM inpatient_totals it
  FULL OUTER JOIN outpatient_totals ot ON it."provider_id" = ot."provider_id"
)
SELECT "provider_id", "provider_name", combined_average_cost
FROM combined_totals
ORDER BY combined_average_cost DESC NULLS LAST
LIMIT 1;