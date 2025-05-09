WITH drg_totals AS (   -- total discharges for every DRG in the 2014 file
    SELECT 
        "drg_definition",
        SUM("total_discharges") AS total_discharges
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "drg_definition"
),

top_drg AS (           -- DRG that has the highest overall number of discharges
    SELECT 
        "drg_definition"
    FROM drg_totals
    ORDER BY total_discharges DESC NULLS LAST
    LIMIT 1
),

drg_rows AS (          -- all rows in the file for that DRG only
    SELECT 
        ic."provider_city",
        ic."total_discharges",
        ic."average_total_payments"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014 ic
    JOIN top_drg td
      ON ic."drg_definition" = td."drg_definition"
),

city_aggregates AS (   -- discharges & weighted-avg payments by city
    SELECT
        "provider_city"                       AS city,
        SUM("total_discharges")               AS city_total_discharges,
        SUM("total_discharges" * "average_total_payments")
          / SUM("total_discharges")           AS weighted_avg_total_payments
    FROM drg_rows
    GROUP BY "provider_city"
),

top_3_cities AS (      -- top 3 cities by discharges for that DRG
    SELECT *
    FROM city_aggregates
    ORDER BY city_total_discharges DESC NULLS LAST
    LIMIT 3
)

SELECT
    (SELECT "drg_definition" FROM top_drg)        AS drg_definition,
    city,
    city_total_discharges,
    weighted_avg_total_payments
FROM top_3_cities
ORDER BY city_total_discharges DESC NULLS LAST;