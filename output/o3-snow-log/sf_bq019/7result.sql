/* 1) find the DRG definition with the greatest total discharges
   2) within that DRG definition, find the three cities with the most discharges
   3) for each of those cities compute the weighted-average total payments
      (weight = total_discharges on each row)                                                  */

WITH drg_leader AS (  -- DRG definition with the most discharges overall
    SELECT
        "drg_definition",
        SUM("total_discharges")   AS drg_total_discharges
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "drg_definition"
    QUALIFY ROW_NUMBER() OVER (ORDER BY drg_total_discharges DESC NULLS LAST) = 1
),

drg_rows AS (         -- all rows belonging to that single DRG definition
    SELECT ic.*
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014 ic
    JOIN drg_leader d
      ON ic."drg_definition" = d."drg_definition"
),

city_agg AS (         -- discharge totals and weighted-payment per city
    SELECT
        "provider_city"                              AS city,
        SUM("total_discharges")                      AS city_discharges,
        SUM("average_total_payments" * "total_discharges")
          / NULLIF(SUM("total_discharges"),0)        AS weighted_avg_total_payments
    FROM drg_rows
    GROUP BY "provider_city"
),

top_cities AS (       -- three cities with the most discharges
    SELECT
        city,
        city_discharges,
        weighted_avg_total_payments,
        ROW_NUMBER() OVER (ORDER BY city_discharges DESC NULLS LAST) AS rn
    FROM city_agg
)

SELECT
    d."drg_definition",
    t.city,
    ROUND(t.weighted_avg_total_payments, 4) AS weighted_avg_total_payments
FROM top_cities t
CROSS JOIN drg_leader d          -- only one row, so safe cross-join
WHERE t.rn <= 3                  -- keep top three cities
ORDER BY t.city_discharges DESC NULLS LAST;