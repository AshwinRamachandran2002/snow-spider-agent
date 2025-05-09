/* -----------------------------------------------------------
   1. Identify the five most frequent minor crime categories in 2008
   2. For every calendar year, calculate what proportion (in %) of
      the year’s total crime these five categories represent.
   3. One row per year – five percentage columns, rounded to 2-dp
-------------------------------------------------------------*/
WITH top5_2008 AS (   -- step-1 : the five leading 2008 categories
    SELECT  "minor_category",
            ROW_NUMBER() OVER (ORDER BY SUM("value") DESC NULLS LAST) AS rn
    FROM    LONDON.LONDON_CRIME."CRIME_BY_LSOA"
    WHERE   "year" = 2008
    GROUP BY "minor_category"
    ORDER BY rn
    LIMIT 5
),
year_totals AS (      -- total crime volume per year
    SELECT  "year",
            SUM("value") AS tot_val
    FROM    LONDON.LONDON_CRIME."CRIME_BY_LSOA"
    GROUP BY "year"
),
year_cat_vals AS (    -- yearly totals for each of the 5 categories
    SELECT  c."year",
            SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5_2008 WHERE rn = 1) THEN c."value" ELSE 0 END) AS cat1_val,
            SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5_2008 WHERE rn = 2) THEN c."value" ELSE 0 END) AS cat2_val,
            SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5_2008 WHERE rn = 3) THEN c."value" ELSE 0 END) AS cat3_val,
            SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5_2008 WHERE rn = 4) THEN c."value" ELSE 0 END) AS cat4_val,
            SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5_2008 WHERE rn = 5) THEN c."value" ELSE 0 END) AS cat5_val
    FROM    LONDON.LONDON_CRIME."CRIME_BY_LSOA"  c
    GROUP BY c."year"
),
final AS (            -- step-2 : convert volumes to shares (percent)
    SELECT  y."year",
            ROUND(100 * c.cat1_val / y.tot_val, 2) AS "CAT1_PCT",
            ROUND(100 * c.cat2_val / y.tot_val, 2) AS "CAT2_PCT",
            ROUND(100 * c.cat3_val / y.tot_val, 2) AS "CAT3_PCT",
            ROUND(100 * c.cat4_val / y.tot_val, 2) AS "CAT4_PCT",
            ROUND(100 * c.cat5_val / y.tot_val, 2) AS "CAT5_PCT"
    FROM    year_totals      y
    JOIN    year_cat_vals    c
           ON y."year" = c."year"
)
SELECT  *
FROM    final
ORDER BY "year";