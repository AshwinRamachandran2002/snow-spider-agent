WITH combined_inpatient AS (
    SELECT "provider_id", "provider_name", "total_discharges", "average_medicare_payments", 2011 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2011
    UNION ALL
    SELECT "provider_id", "provider_name", "total_discharges", "average_medicare_payments", 2012 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2012
    UNION ALL
    SELECT "provider_id", "provider_name", "total_discharges", "average_medicare_payments", 2013 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2013
    UNION ALL
    SELECT "provider_id", "provider_name", "total_discharges", "average_medicare_payments", 2014 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    UNION ALL
    SELECT "provider_id", "provider_name", "total_discharges", "average_medicare_payments", 2015 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2015
),
total_inpatient_cost_per_provider AS (
    SELECT "provider_id", "provider_name", SUM("total_discharges" * "average_medicare_payments") AS "total_inpatient_cost"
    FROM combined_inpatient
    GROUP BY "provider_id", "provider_name"
),
top_provider AS (
    SELECT "provider_id", "provider_name"
    FROM total_inpatient_cost_per_provider
    ORDER BY "total_inpatient_cost" DESC NULLS LAST
    LIMIT 1
),
yearly_inpatient_cost AS (
    SELECT c."Year", AVG(c."total_discharges" * c."average_medicare_payments") AS "Average_Inpatient_Cost"
    FROM combined_inpatient c
    JOIN top_provider tp ON c."provider_id" = tp."provider_id"
    GROUP BY c."Year"
),
combined_outpatient AS (
    SELECT "provider_id", "provider_name", "outpatient_services", "average_total_payments", 2011 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2011
    UNION ALL
    SELECT "provider_id", "provider_name", "outpatient_services", "average_total_payments", 2012 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2012
    UNION ALL
    SELECT "provider_id", "provider_name", "outpatient_services", "average_total_payments", 2013 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2013
    UNION ALL
    SELECT "provider_id", "provider_name", "outpatient_services", "average_total_payments", 2014 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    UNION ALL
    SELECT "provider_id", "provider_name", "outpatient_services", "average_total_payments", 2015 AS "Year"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2015
),
yearly_outpatient_cost AS (
    SELECT c."Year", AVG(c."outpatient_services" * c."average_total_payments") AS "Average_Outpatient_Cost"
    FROM combined_outpatient c
    JOIN top_provider tp ON c."provider_id" = tp."provider_id"
    GROUP BY c."Year"
)
SELECT y."Year", y."Average_Inpatient_Cost", yo."Average_Outpatient_Cost"
FROM yearly_inpatient_cost y
LEFT JOIN yearly_outpatient_cost yo ON y."Year" = yo."Year"
ORDER BY y."Year";