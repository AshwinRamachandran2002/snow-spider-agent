WITH top_provider AS (
  SELECT "provider_id"
  FROM (
    SELECT "provider_id",
      SUM("average_medicare_payments" * "total_discharges") AS "total_inpatient_cost"
    FROM (
      SELECT "provider_id", "average_medicare_payments", "total_discharges"
      FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
      UNION ALL
      SELECT "provider_id", "average_medicare_payments", "total_discharges"
      FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
      UNION ALL
      SELECT "provider_id", "average_medicare_payments", "total_discharges"
      FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
      UNION ALL
      SELECT "provider_id", "average_medicare_payments", "total_discharges"
      FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
      UNION ALL
      SELECT "provider_id", "average_medicare_payments", "total_discharges"
      FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
    ) t
    GROUP BY "provider_id"
    ORDER BY "total_inpatient_cost" DESC NULLS LAST
    LIMIT 1
  )
)
SELECT
  '2011' AS "Year",
  ROUND(AVG(ic."average_medicare_payments" * ic."total_discharges"), 4) AS "Average_Inpatient_Cost",
  ROUND(AVG(oc."average_total_payments" * oc."outpatient_services"), 4) AS "Average_Outpatient_Cost"
FROM top_provider tp
LEFT JOIN CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011 ic ON ic."provider_id" = tp."provider_id"
LEFT JOIN CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011 oc ON oc."provider_id" = tp."provider_id"
UNION ALL
SELECT
  '2012' AS "Year",
  ROUND(AVG(ic."average_medicare_payments" * ic."total_discharges"), 4) AS "Average_Inpatient_Cost",
  ROUND(AVG(oc."average_total_payments" * oc."outpatient_services"), 4) AS "Average_Outpatient_Cost"
FROM top_provider tp
LEFT JOIN CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012 ic ON ic."provider_id" = tp."provider_id"
LEFT JOIN CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012 oc ON oc."provider_id" = tp."provider_id"
UNION ALL
SELECT
  '2013' AS "Year",
  ROUND(AVG(ic."average_medicare_payments" * ic."total_discharges"), 4) AS "Average_Inpatient_Cost",
  ROUND(AVG(oc."average_total_payments" * oc."outpatient_services"), 4) AS "Average_Outpatient_Cost"
FROM top_provider tp
LEFT JOIN CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013 ic ON ic."provider_id" = tp."provider_id"
LEFT JOIN CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013 oc ON oc."provider_id" = tp."provider_id"
UNION ALL
SELECT
  '2014' AS "Year",
  ROUND(AVG(ic."average_medicare_payments" * ic."total_discharges"), 4) AS "Average_Inpatient_Cost",
  ROUND(AVG(oc."average_total_payments" * oc."outpatient_services"), 4) AS "Average_Outpatient_Cost"
FROM top_provider tp
LEFT JOIN CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014 ic ON ic."provider_id" = tp."provider_id"
LEFT JOIN CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014 oc ON oc."provider_id" = tp."provider_id"
UNION ALL
SELECT
  '2015' AS "Year",
  ROUND(AVG(ic."average_medicare_payments" * ic."total_discharges"), 4) AS "Average_Inpatient_Cost",
  ROUND(AVG(oc."average_total_payments" * oc."outpatient_services"), 4) AS "Average_Outpatient_Cost"
FROM top_provider tp
LEFT JOIN CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015 ic ON ic."provider_id" = tp."provider_id"
LEFT JOIN CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015 oc ON oc."provider_id" = tp."provider_id"
ORDER BY "Year";