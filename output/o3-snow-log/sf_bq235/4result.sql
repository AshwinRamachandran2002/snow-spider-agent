WITH inpatient_avg AS (
    SELECT
        "provider_id",
        "provider_name",
        AVG("average_total_payments") AS avg_inpatient_cost
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY
        "provider_id",
        "provider_name"
),
outpatient_avg AS (
    SELECT
        "provider_id",
        AVG("average_total_payments") AS avg_outpatient_cost
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY
        "provider_id"
)
SELECT
    ia."provider_id",
    ia."provider_name",
    ia.avg_inpatient_cost,
    oa.avg_outpatient_cost,
    (ia.avg_inpatient_cost + oa.avg_outpatient_cost) AS combined_average_cost
FROM inpatient_avg ia
JOIN outpatient_avg oa
  ON ia."provider_id" = oa."provider_id"
ORDER BY combined_average_cost DESC NULLS LAST
LIMIT 1;