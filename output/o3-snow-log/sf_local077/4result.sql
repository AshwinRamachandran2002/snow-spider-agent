WITH monthly_interest AS (
    /* 1.  Calculate average composition per interest for each month in scope */
    SELECT
        TO_DATE('01-' || "month_year", 'DD-MM-YYYY')              AS "month_date",
        "month_year",
        "interest_id",
        /* avg_comp = composition / index_value  */
        CASE 
            WHEN "index_value" = 0 THEN NULL
            ELSE "composition" / "index_value"
        END                                                      AS "avg_comp"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS
    WHERE (("_year" = 2018 AND "_month" BETWEEN 9 AND 12)
           OR ("_year" = 2019 AND "_month" BETWEEN 1 AND 8))
), ranked_monthly AS (
    /* 2.  Rank interests by avg_comp within each month */
    SELECT
        "month_date",
        "month_year",
        "interest_id",
        "avg_comp",
        ROW_NUMBER() OVER (PARTITION BY "month_date" 
                           ORDER BY "avg_comp" DESC NULLS LAST)   AS "rn"
    FROM monthly_interest
), monthly_max AS (
    /* 3.  Keep only the top-ranked interest for each month */
    SELECT
        "month_date",
        "month_year",
        "interest_id",
        "avg_comp"                                                AS "max_index_composition"
    FROM ranked_monthly
    WHERE "rn" = 1
), monthly_max_with_name AS (
    /* 4.  Bring in the interest name */
    SELECT
        m."month_date",
        m."month_year",
        i."interest_name",
        m."max_index_composition"
    FROM monthly_max m
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP i
           ON m."interest_id" = i."id"
), final_calc AS (
    /* 5.  Add 3-month rolling average and previous-month details */
    SELECT
        "month_date",
        "month_year",
        "interest_name",
        "max_index_composition",
        AVG("max_index_composition") 
            OVER (ORDER BY "month_date" 
                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)       AS "rolling_avg_3m",
        LAG("interest_name", 1) 
            OVER (ORDER BY "month_date")                          AS "interest_name_m1",
        LAG("max_index_composition", 1) 
            OVER (ORDER BY "month_date")                          AS "max_comp_m1",
        LAG("interest_name", 2) 
            OVER (ORDER BY "month_date")                          AS "interest_name_m2",
        LAG("max_index_composition", 2) 
            OVER (ORDER BY "month_date")                          AS "max_comp_m2"
    FROM monthly_max_with_name
)
SELECT
    "month_year"                                                 AS "date",
    "interest_name",
    ROUND("max_index_composition", 4)                            AS "max_index_composition",
    ROUND("rolling_avg_3m", 4)                                   AS "rolling_avg_3m",
    "interest_name_m1",
    ROUND("max_comp_m1", 4)                                      AS "max_index_composition_m1",
    "interest_name_m2",
    ROUND("max_comp_m2", 4)                                      AS "max_index_composition_m2"
FROM final_calc
ORDER BY "month_date" ASC;