WITH inpatient AS (
    SELECT
        '2011' AS "Year",
        ROUND(SUM("total_discharges" * "average_total_payments") / NULLIF(SUM("total_discharges"), 0), 4) AS "Inpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2012' AS "Year",
        ROUND(SUM("total_discharges" * "average_total_payments") / NULLIF(SUM("total_discharges"), 0), 4) AS "Inpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2013' AS "Year",
        ROUND(SUM("total_discharges" * "average_total_payments") / NULLIF(SUM("total_discharges"), 0), 4) AS "Inpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2014' AS "Year",
        ROUND(SUM("total_discharges" * "average_total_payments") / NULLIF(SUM("total_discharges"), 0), 4) AS "Inpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2015' AS "Year",
        ROUND(SUM("total_discharges" * "average_total_payments") / NULLIF(SUM("total_discharges"), 0), 4) AS "Inpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
    WHERE "provider_id" = '330101'
),
outpatient AS (
    SELECT
        '2011' AS "Year",
        ROUND(SUM("outpatient_services" * "average_total_payments") / NULLIF(SUM("outpatient_services"), 0), 4) AS "Outpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2012' AS "Year",
        ROUND(SUM("outpatient_services" * "average_total_payments") / NULLIF(SUM("outpatient_services"), 0), 4) AS "Outpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2013' AS "Year",
        ROUND(SUM("outpatient_services" * "average_total_payments") / NULLIF(SUM("outpatient_services"), 0), 4) AS "Outpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2014' AS "Year",
        ROUND(SUM("outpatient_services" * "average_total_payments") / NULLIF(SUM("outpatient_services"), 0), 4) AS "Outpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    WHERE "provider_id" = '330101'
    UNION ALL
    SELECT
        '2015' AS "Year",
        ROUND(SUM("outpatient_services" * "average_total_payments") / NULLIF(SUM("outpatient_services"), 0), 4) AS "Outpatient_Revenue_Avg_Per_Case"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
    WHERE "provider_id" = '330101'
)
SELECT
    inpatient."Year",
    inpatient."Inpatient_Revenue_Avg_Per_Case",
    outpatient."Outpatient_Revenue_Avg_Per_Case"
FROM inpatient
JOIN outpatient ON inpatient."Year" = outpatient."Year"
ORDER BY inpatient."Year";