WITH drg_totals AS (
    /* find total discharges for every DRG definition */
    SELECT 
        "drg_definition",
        SUM("total_discharges") AS "total_discharges_sum"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "drg_definition"
),
top_drg AS (
    /* pick the DRG definition with the highest total discharges */
    SELECT 
        "drg_definition"
    FROM drg_totals
    QUALIFY ROW_NUMBER() OVER (ORDER BY "total_discharges_sum" DESC) = 1
),
drg_city_agg AS (
    /* for that DRG, aggregate by city and compute
       weighted-average total payments (weight = total discharges) */
    SELECT
        td."drg_definition",
        ic."provider_city"                            AS "city",
        SUM(ic."total_discharges")                    AS "city_total_discharges",
        SUM(ic."total_discharges" * COALESCE(ic."average_total_payments",0))
            / NULLIF(SUM(ic."total_discharges"),0)   AS "weighted_avg_total_payments"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014 ic
    JOIN top_drg td
      ON ic."drg_definition" = td."drg_definition"
    GROUP BY td."drg_definition", ic."provider_city"
),
top3_cities AS (
    /* keep the three cities with the most discharges for that DRG */
    SELECT *
    FROM drg_city_agg
    ORDER BY "city_total_discharges" DESC NULLS LAST
    LIMIT 3
)
SELECT
    "drg_definition",
    "city",
    "weighted_avg_total_payments"
FROM top3_cities
ORDER BY "city_total_discharges" DESC NULLS LAST;