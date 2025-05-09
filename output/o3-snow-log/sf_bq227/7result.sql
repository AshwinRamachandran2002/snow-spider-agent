/*  1) work out the five largest “minor_category” groups in 2008
    2) keep those five categories and calculate, for every year,
       what % of that year’s total crime they represent                */

WITH top5 AS (        -- five biggest minor-categories in 2008
        SELECT  "minor_category",
                ROW_NUMBER() OVER (ORDER BY SUM("value") DESC)  AS rn
        FROM    LONDON.LONDON_CRIME."CRIME_BY_LSOA"
        WHERE   "year" = 2008
        GROUP BY "minor_category"
        ORDER BY SUM("value") DESC
        LIMIT 5
),

year_totals AS (      -- total number of crimes each year (all categories)
        SELECT  "year",
                SUM("value") AS total_crimes
        FROM    LONDON.LONDON_CRIME."CRIME_BY_LSOA"
        GROUP BY "year"
),

year_cat AS (         -- yearly totals for ONLY the 5 chosen categories
        SELECT  c."year",
                c."minor_category",
                SUM(c."value") AS cat_total
        FROM    LONDON.LONDON_CRIME."CRIME_BY_LSOA"  c
        JOIN    top5 t
          ON    c."minor_category" = t."minor_category"
        GROUP BY c."year", c."minor_category"
)

/* final report – one row per year, five percentage columns            */
SELECT
        yc."year",

        /* percentage columns (rounded to two decimals) */
        ROUND( 100 * SUM( CASE WHEN yc."minor_category" =
                                  (SELECT "minor_category" FROM top5 WHERE rn = 1)
                              THEN yc.cat_total END ) / yt.total_crimes , 2 )  AS "CATEGORY_1_PCT",

        ROUND( 100 * SUM( CASE WHEN yc."minor_category" =
                                  (SELECT "minor_category" FROM top5 WHERE rn = 2)
                              THEN yc.cat_total END ) / yt.total_crimes , 2 )  AS "CATEGORY_2_PCT",

        ROUND( 100 * SUM( CASE WHEN yc."minor_category" =
                                  (SELECT "minor_category" FROM top5 WHERE rn = 3)
                              THEN yc.cat_total END ) / yt.total_crimes , 2 )  AS "CATEGORY_3_PCT",

        ROUND( 100 * SUM( CASE WHEN yc."minor_category" =
                                  (SELECT "minor_category" FROM top5 WHERE rn = 4)
                              THEN yc.cat_total END ) / yt.total_crimes , 2 )  AS "CATEGORY_4_PCT",

        ROUND( 100 * SUM( CASE WHEN yc."minor_category" =
                                  (SELECT "minor_category" FROM top5 WHERE rn = 5)
                              THEN yc.cat_total END ) / yt.total_crimes , 2 )  AS "CATEGORY_5_PCT"

FROM        year_cat   yc
JOIN        year_totals yt
      ON    yc."year" = yt."year"
GROUP BY    yc."year", yt.total_crimes
ORDER BY    yc."year";