WITH drg_totals AS (   -- total discharges for every DRG definition
    SELECT 
        "drg_definition",
        SUM("total_discharges")                            AS total_discharges
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "drg_definition"
), 
top_drg AS (           -- DRG definition with the most total discharges
    SELECT 
        "drg_definition"
    FROM drg_totals
    ORDER BY total_discharges DESC NULLS LAST
    LIMIT 1
), 
filtered AS (          -- only rows for that DRG definition
    SELECT 
        ic."provider_city"                    AS city,
        ic."total_discharges",
        ic."average_total_payments"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014 ic
    JOIN top_drg t
      ON ic."drg_definition" = t."drg_definition"
), 
city_agg AS (          -- weighted-payment numerators & denominators by city
    SELECT 
        city,
        SUM("total_discharges")                                       AS sum_discharges,
        SUM("average_total_payments" * "total_discharges")            AS weighted_payment_sum
    FROM filtered
    GROUP BY city
), 
top_cities AS (        -- pick top-3 cities by discharge count
    SELECT 
        city,
        sum_discharges,
        weighted_payment_sum,
        ROW_NUMBER() OVER (ORDER BY sum_discharges DESC NULLS LAST)   AS rn
    FROM city_agg
)
SELECT 
    city,
    weighted_payment_sum / sum_discharges  AS weighted_avg_total_payments
FROM top_cities
WHERE rn <= 3
ORDER BY sum_discharges DESC NULLS LAST;