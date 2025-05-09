WITH inpt AS (
    SELECT 
        "provider_id",
        AVG("average_total_payments") AS avg_inpatient_cost
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
outpt AS (
    SELECT 
        "provider_id",
        AVG("average_total_payments") AS avg_outpatient_cost
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
names AS (
    SELECT 
        "provider_id",
        MAX("provider_name") AS provider_name
    FROM (
          SELECT "provider_id", "provider_name"
          FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
          UNION ALL
          SELECT "provider_id", "provider_name"
          FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    )
    GROUP BY "provider_id"
),
combined AS (
    SELECT
        COALESCE(i."provider_id", o."provider_id")                             AS provider_id,
        i.avg_inpatient_cost,
        o.avg_outpatient_cost,
        COALESCE(i.avg_inpatient_cost, 0) + COALESCE(o.avg_outpatient_cost,0) AS combined_avg_cost
    FROM inpt i
    FULL OUTER JOIN outpt o
        ON i."provider_id" = o."provider_id"
)
SELECT 
    n.provider_name,
    c.provider_id,
    ROUND(c.avg_inpatient_cost, 2)  AS avg_inpatient_cost,
    ROUND(c.avg_outpatient_cost, 2) AS avg_outpatient_cost,
    ROUND(c.combined_avg_cost, 2)   AS combined_avg_cost
FROM combined c
JOIN names n 
  ON n."provider_id" = c.provider_id
ORDER BY c.combined_avg_cost DESC NULLS LAST
LIMIT 1;