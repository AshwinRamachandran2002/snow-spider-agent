WITH drg_totals AS (
    /* 1.  Find total discharges for every DRG definition */
    SELECT 
        "drg_definition",
        SUM("total_discharges") AS total_discharges
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "drg_definition"
),
top_drg AS (
    /* 2.  Pick the DRG definition with the highest number of discharges */
    SELECT 
        "drg_definition"
    FROM drg_totals
    ORDER BY total_discharges DESC NULLS LAST
    LIMIT 1
),
city_stats AS (
    /* 3.  For that DRG, compute city-level totals and weighted avg payments */
    SELECT
        ic."provider_city"                               AS city,
        SUM(ic."total_discharges")                       AS city_total_discharges,
        SUM(ic."total_discharges" * ic."average_total_payments")
          / SUM(ic."total_discharges")                   AS weighted_avg_total_payments
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014 ic
    JOIN top_drg td
      ON ic."drg_definition" = td."drg_definition"
    GROUP BY ic."provider_city"
)
SELECT
    (SELECT "drg_definition" FROM top_drg)               AS drg_definition,
    city,
    weighted_avg_total_payments
FROM city_stats
ORDER BY city_total_discharges DESC NULLS LAST
LIMIT 3;