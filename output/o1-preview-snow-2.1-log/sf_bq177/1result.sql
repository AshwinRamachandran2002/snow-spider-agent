SELECT
  COALESCE(inpatient."year", outpatient."year") AS "Year",
  ROUND(inpatient."avg_inpatient_revenue_per_case", 4) AS "Inpatient_Revenue_Avg_Per_Case",
  ROUND(outpatient."avg_outpatient_revenue_per_case", 4) AS "Outpatient_Revenue_Avg_Per_Case"
FROM (
  SELECT
    "year",
    SUM("inpatient_total_charges") / SUM("total_discharges") AS "avg_inpatient_revenue_per_case"
  FROM (
    SELECT '2011' AS "year", "provider_id", "total_discharges", ("total_discharges" * "average_covered_charges") AS "inpatient_total_charges"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
    UNION ALL
    SELECT '2012', "provider_id", "total_discharges", ("total_discharges" * "average_covered_charges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
    UNION ALL
    SELECT '2013', "provider_id", "total_discharges", ("total_discharges" * "average_covered_charges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
    UNION ALL
    SELECT '2014', "provider_id", "total_discharges", ("total_discharges" * "average_covered_charges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    UNION ALL
    SELECT '2015', "provider_id", "total_discharges", ("total_discharges" * "average_covered_charges")
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
  ) AS inpatient_data
  WHERE "provider_id" = (
    SELECT "provider_id"
    FROM (
      SELECT "provider_id", SUM("total_charges") AS "total_inpatient_charges"
      FROM (
        SELECT "provider_id", ("total_discharges" * "average_covered_charges") AS "total_charges"
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
      ) AS combined_inpatient
      GROUP BY "provider_id"
      ORDER BY "total_inpatient_charges" DESC NULLS LAST
      LIMIT 1
    )
  )
  GROUP BY "year"
) AS inpatient
FULL OUTER JOIN (
  SELECT
    "year",
    SUM("outpatient_total_charges") / SUM("outpatient_services") AS "avg_outpatient_revenue_per_case"
  FROM (
    SELECT '2011' AS "year", "provider_id", "outpatient_services", ("outpatient_services" * "average_estimated_submitted_charges") AS "outpatient_total_charges"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
    UNION ALL
    SELECT '2012', "provider_id", "outpatient_services", ("outpatient_services" * "average_estimated_submitted_charges")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
    UNION ALL
    SELECT '2013', "provider_id", "outpatient_services", ("outpatient_services" * "average_estimated_submitted_charges")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
    UNION ALL
    SELECT '2014', "provider_id", "outpatient_services", ("outpatient_services" * "average_estimated_submitted_charges")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    UNION ALL
    SELECT '2015', "provider_id", "outpatient_services", ("outpatient_services" * "average_estimated_submitted_charges")
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
  ) AS outpatient_data
  WHERE "provider_id" = (
    SELECT "provider_id"
    FROM (
      SELECT "provider_id", SUM("total_charges") AS "total_inpatient_charges"
      FROM (
        SELECT "provider_id", ("total_discharges" * "average_covered_charges") AS "total_charges"
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
        UNION ALL
        SELECT "provider_id", ("total_discharges" * "average_covered_charges")
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
      ) AS combined_inpatient
      GROUP BY "provider_id"
      ORDER BY "total_inpatient_charges" DESC NULLS LAST
      LIMIT 1
    )
  )
  GROUP BY "year"
) AS outpatient ON inpatient."year" = outpatient."year"
ORDER BY COALESCE(inpatient."year", outpatient."year") NULLS LAST;