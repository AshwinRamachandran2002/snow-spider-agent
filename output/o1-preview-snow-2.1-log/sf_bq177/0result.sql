WITH provider_totals AS (
    SELECT "provider_id",
           SUM("total_inpatient_payments") AS "total_payments"
    FROM (
        SELECT "provider_id",
               SUM("total_discharges" * "average_total_payments") AS "total_inpatient_payments"
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
        GROUP BY "provider_id"
        UNION ALL
        SELECT "provider_id",
               SUM("total_discharges" * "average_total_payments") AS "total_inpatient_payments"
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
        GROUP BY "provider_id"
        UNION ALL
        SELECT "provider_id",
               SUM("total_discharges" * "average_total_payments") AS "total_inpatient_payments"
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
        GROUP BY "provider_id"
        UNION ALL
        SELECT "provider_id",
               SUM("total_discharges" * "average_total_payments") AS "total_inpatient_payments"
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
        GROUP BY "provider_id"
        UNION ALL
        SELECT "provider_id",
               SUM("total_discharges" * "average_total_payments") AS "total_inpatient_payments"
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
        GROUP BY "provider_id"
    ) AS yearly_totals
    GROUP BY "provider_id"
    ORDER BY "total_payments" DESC NULLS LAST
    LIMIT 1
),
yearly_averages AS (
    SELECT '2011' AS "Year",
           ROUND(AVG("average_total_payments"), 4) AS "Inpatient_Revenue_Avg_Per_Case",
           ROUND(
               (SELECT AVG("average_total_payments")
                FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2011"
                WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
               ), 4) AS "Outpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
    WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
    UNION ALL
    SELECT '2012',
           ROUND(AVG("average_total_payments"), 4),
           ROUND(
               (SELECT AVG("average_total_payments")
                FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2012"
                WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
               ), 4)
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
    WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
    UNION ALL
    SELECT '2013',
           ROUND(AVG("average_total_payments"), 4),
           ROUND(
               (SELECT AVG("average_total_payments")
                FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2013"
                WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
               ), 4)
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
    WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
    UNION ALL
    SELECT '2014',
           ROUND(AVG("average_total_payments"), 4),
           ROUND(
               (SELECT AVG("average_total_payments")
                FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2014"
                WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
               ), 4)
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
    UNION ALL
    SELECT '2015',
           ROUND(AVG("average_total_payments"), 4),
           ROUND(
               (SELECT AVG("average_total_payments")
                FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2015"
                WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
               ), 4)
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
    WHERE "provider_id" = (SELECT "provider_id" FROM provider_totals)
)
SELECT "Year", "Inpatient_Revenue_Avg_Per_Case", "Outpatient_Revenue_Avg_Per_Case"
FROM yearly_averages
ORDER BY "Year";