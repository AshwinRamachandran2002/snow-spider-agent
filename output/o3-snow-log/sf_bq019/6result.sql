WITH drg_rank AS (   -- find the DRG with the most total discharges
    SELECT
        "drg_definition",
        SUM("total_discharges")               AS total_discharges,
        ROW_NUMBER() OVER (ORDER BY SUM("total_discharges") DESC) AS rn
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    GROUP BY "drg_definition"
),
target_drg AS (      -- keep only the top-discharge DRG
    SELECT "drg_definition"
    FROM   drg_rank
    WHERE  rn = 1
),
city_agg AS (        -- aggregate discharges and weighted payments by city for that DRG
    SELECT
        ic."provider_city"                              AS city,
        SUM(ic."total_discharges")                      AS city_discharges,
        SUM(ic."average_total_payments" * ic."total_discharges") AS weighted_payment_sum
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014" ic
    JOIN target_drg t
      ON ic."drg_definition" = t."drg_definition"
    GROUP BY ic."provider_city"
),
city_rank AS (       -- compute weighted average total payment and rank cities by discharges
    SELECT
        city,
        city_discharges,
        weighted_payment_sum / city_discharges          AS weighted_avg_total_payments,
        ROW_NUMBER() OVER (ORDER BY city_discharges DESC) AS rn
    FROM city_agg
)
SELECT
    city,
    weighted_avg_total_payments
FROM   city_rank
WHERE  rn <= 3                   -- top three cities by discharges
ORDER  BY city_discharges DESC;  -- keep the order by most discharges