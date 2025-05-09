WITH inpatient AS (
    SELECT
        "provider_id",
        AVG("average_total_payments") AS inpatient_avg
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
outpatient AS (
    SELECT
        "provider_id",
        AVG("average_total_payments") AS outpatient_avg
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
combined AS (
    SELECT
        COALESCE(i."provider_id", o."provider_id")        AS provider_id,
        i.inpatient_avg,
        o.outpatient_avg,
        COALESCE(i.inpatient_avg, 0) +
        COALESCE(o.outpatient_avg, 0)                     AS combined_avg
    FROM inpatient i
    FULL OUTER JOIN outpatient o
        ON i."provider_id" = o."provider_id"
),
provider_names AS (
    SELECT DISTINCT "provider_id", "provider_name"
    FROM (
        SELECT "provider_id", "provider_name"
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
        UNION ALL
        SELECT "provider_id", "provider_name"
        FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    )
)
SELECT
    c.provider_id,
    p."provider_name",
    c.inpatient_avg,
    c.outpatient_avg,
    c.combined_avg
FROM combined            c
LEFT JOIN provider_names p
       ON p."provider_id" = c.provider_id
ORDER BY c.combined_avg DESC NULLS LAST
LIMIT 1;