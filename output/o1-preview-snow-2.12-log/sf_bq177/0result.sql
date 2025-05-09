WITH Inpatient_Costs AS (
  SELECT '2011' AS "Year",
    AVG("average_medicare_payments" * "total_discharges") AS "Average_Inpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2012' AS "Year",
    AVG("average_medicare_payments" * "total_discharges") AS "Average_Inpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2013' AS "Year",
    AVG("average_medicare_payments" * "total_discharges") AS "Average_Inpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2014' AS "Year",
    AVG("average_medicare_payments" * "total_discharges") AS "Average_Inpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2015' AS "Year",
    AVG("average_medicare_payments" * "total_discharges") AS "Average_Inpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
  WHERE "provider_id" = '330101'
),
Outpatient_Costs AS (
  SELECT '2011' AS "Year",
    AVG("average_total_payments" * "outpatient_services") AS "Average_Outpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2012' AS "Year",
    AVG("average_total_payments" * "outpatient_services") AS "Average_Outpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2013' AS "Year",
    AVG("average_total_payments" * "outpatient_services") AS "Average_Outpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2014' AS "Year",
    AVG("average_total_payments" * "outpatient_services") AS "Average_Outpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
  WHERE "provider_id" = '330101'

  UNION ALL

  SELECT '2015' AS "Year",
    AVG("average_total_payments" * "outpatient_services") AS "Average_Outpatient_Cost"
  FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
  WHERE "provider_id" = '330101'
)

SELECT
  i."Year",
  ROUND(COALESCE(i."Average_Inpatient_Cost", 0), 4) AS "Average_Inpatient_Cost",
  ROUND(COALESCE(o."Average_Outpatient_Cost", 0), 4) AS "Average_Outpatient_Cost"
FROM
  Inpatient_Costs i
  LEFT JOIN Outpatient_Costs o ON i."Year" = o."Year"
ORDER BY
  i."Year";