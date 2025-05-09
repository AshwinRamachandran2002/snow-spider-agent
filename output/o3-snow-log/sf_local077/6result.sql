/* ---------------------------------------------------------
   Monthly max-index-composition and 3-month rolling average
   Period : Sep-2018  →  Aug-2019
---------------------------------------------------------*/
WITH base AS (
    SELECT
        im."month_year",
        im."interest_id",
        im."composition",
        im."index_value",
        im."composition" / NULLIF(im."index_value",0)                                AS "avg_comp",
        /* robust month-start parser for both 07-2018 and 2018-07 formats */
        COALESCE(
            TRY_TO_DATE(im."month_year",'MM-YYYY'),
            TRY_TO_DATE(im."month_year",'YYYY-MM')
        )                                                                            AS "month_start"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS" im
    WHERE COALESCE(
              TRY_TO_DATE(im."month_year",'MM-YYYY'),
              TRY_TO_DATE(im."month_year",'YYYY-MM')
          ) BETWEEN '2018-09-01'::DATE AND '2019-08-31'::DATE
),
top_per_month AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (PARTITION BY b."month_year"
                           ORDER BY b."avg_comp" DESC NULLS LAST)                     AS "rn"
    FROM base b
),
monthly_max AS (
    SELECT
        "month_year",
        "interest_id",
        "avg_comp"                                                                    AS "max_index_comp",
        "month_start"
    FROM top_per_month
    WHERE "rn" = 1
),
monthly_max_named AS (
    SELECT
        mm."month_year",
        COALESCE(map."interest_name",'UNKNOWN')                                       AS "interest_name",
        mm."max_index_comp",
        mm."month_start"
    FROM monthly_max mm
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP" map
           ON map."id" = CAST(mm."interest_id" AS NUMBER)
),
rolling_calc AS (
    SELECT
        m.*,
        AVG(m."max_index_comp")
            OVER (ORDER BY m."month_start"
                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)                          AS "rolling_avg_3m"
    FROM monthly_max_named m
),
lagged AS (
    SELECT
        rc."month_year",
        rc."interest_name"                                                            AS "current_interest_name",
        rc."max_index_comp"                                                           AS "current_max_index_comp",
        rc."rolling_avg_3m",
        LAG(rc."interest_name",1) OVER (ORDER BY rc."month_start")                    AS "prev1_interest_name",
        LAG(rc."max_index_comp",1) OVER (ORDER BY rc."month_start")                   AS "prev1_max_index_comp",
        LAG(rc."interest_name",2) OVER (ORDER BY rc."month_start")                    AS "prev2_interest_name",
        LAG(rc."max_index_comp",2) OVER (ORDER BY rc."month_start")                   AS "prev2_max_index_comp",
        rc."month_start"
    FROM rolling_calc rc
)
SELECT
    "month_year"                                                                     AS "date",
    "current_interest_name"                                                          AS "interest_name",
    ROUND("current_max_index_comp",4)                                                AS "max_index_composition",
    ROUND("rolling_avg_3m",4)                                                        AS "rolling_avg_3m",
    "prev1_interest_name",
    ROUND("prev1_max_index_comp",4)                                                  AS "prev1_max_index_composition",
    "prev2_interest_name",
    ROUND("prev2_max_index_comp",4)                                                  AS "prev2_max_index_composition"
FROM lagged
ORDER BY "month_start";