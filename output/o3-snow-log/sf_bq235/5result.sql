WITH inpatient_agg AS (      -- average inpatient cost per provider (2014)
    SELECT 
        "provider_id",
        AVG("average_total_payments") AS "avg_inpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
outpatient_agg AS (          -- average outpatient cost per provider (2014)
    SELECT 
        "provider_id",
        AVG("average_total_payments") AS "avg_outpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
combined AS (                -- merge inpatient & outpatient averages
    SELECT 
        COALESCE(i."provider_id", o."provider_id")                            AS "provider_id",
        i."avg_inpatient_cost",
        o."avg_outpatient_cost",
        COALESCE(i."avg_inpatient_cost", 0) + COALESCE(o."avg_outpatient_cost", 0) 
            AS "combined_avg_cost"
    FROM inpatient_agg i
    FULL OUTER JOIN outpatient_agg o
        ON i."provider_id" = o."provider_id"
),
provider_names AS (          -- unique provider_id → provider_name mapping
    SELECT DISTINCT "provider_id", "provider_name"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    UNION
    SELECT DISTINCT "provider_id", "provider_name"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
)
SELECT 
    c."provider_id",
    pn."provider_name",
    c."avg_inpatient_cost",
    c."avg_outpatient_cost",
    c."combined_avg_cost"
FROM combined c
JOIN provider_names pn
  ON c."provider_id" = pn."provider_id"
ORDER BY c."combined_avg_cost" DESC NULLS LAST
LIMIT 1;