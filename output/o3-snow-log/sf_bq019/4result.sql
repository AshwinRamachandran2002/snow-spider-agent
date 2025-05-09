WITH drg_totals AS (   -- total discharges per DRG definition
    SELECT
        "drg_definition",
        SUM("total_discharges") AS total_discharges
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    GROUP BY "drg_definition"
),
max_drg AS (           -- DRG definition having the most discharges
    SELECT
        "drg_definition"
    FROM drg_totals
    ORDER BY total_discharges DESC NULLS LAST
    LIMIT 1
),
city_stats AS (        -- discharges and weighted-payment components by city for that DRG
    SELECT
        ic."provider_city"                              AS "city",
        SUM(ic."total_discharges")                      AS city_discharges,
        SUM(ic."average_total_payments" * ic."total_discharges") AS weighted_payment_sum
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014" ic
    JOIN max_drg md
      ON ic."drg_definition" = md."drg_definition"
    GROUP BY ic."provider_city"
),
top_cities AS (        -- top-3 cities by discharges
    SELECT *
    FROM city_stats
    ORDER BY city_discharges DESC NULLS LAST
    LIMIT 3
)
SELECT
    md."drg_definition",
    tc."city",
    tc.city_discharges,
    ROUND(tc.weighted_payment_sum / tc.city_discharges, 4) AS weighted_avg_total_payments
FROM top_cities tc
CROSS JOIN max_drg md
ORDER BY tc.city_discharges DESC NULLS LAST;