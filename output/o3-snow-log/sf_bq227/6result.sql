/* 1) work-out the five most common “minor_category” values in 2008
   2) for every later year add up how many crimes each of those five
      categories recorded
   3) divide by that year’s total number of crimes
   4) put the five percentages next to one another so that every
      year is shown on a single row                                                */

WITH  top5_2008 AS (                       -- step-1
        SELECT  "minor_category",
                SUM("value")           AS total_2008,
                ROW_NUMBER() OVER(ORDER BY SUM("value") DESC)  AS rn
        FROM    LONDON.LONDON_CRIME.CRIME_BY_LSOA
        WHERE   "year" = 2008
        GROUP BY "minor_category"
        ORDER BY total_2008 DESC
        LIMIT   5
),
year_totals AS (                           -- total crimes per year (all types)
        SELECT  "year",
                SUM("value") AS total_crimes
        FROM    LONDON.LONDON_CRIME.CRIME_BY_LSOA
        GROUP BY "year"
),
top5_yearly_totals AS (                    -- step-2 : yearly totals for those 5 cats
        SELECT  c."year",
                c."minor_category",
                SUM(c."value") AS cat_total
        FROM    LONDON.LONDON_CRIME.CRIME_BY_LSOA  c
        JOIN    top5_2008                         t
               ON c."minor_category" = t."minor_category"
        GROUP BY c."year", c."minor_category"
),
percentages AS (                           -- step-3 : convert to %
        SELECT  y."year",
                y."minor_category",
                ROUND( (y.cat_total / t.total_crimes) * 100 , 2 ) AS pct_share
        FROM    top5_yearly_totals  y
        JOIN    year_totals         t
               ON y."year" = t."year"
)
/* step-4 : pivot so that each year is only one row.
   Column names are kept generic (“CATEGORY_1” … “CATEGORY_5”);
   they correspond to the order of popularity found in 2008.  */
SELECT
        "year",

        MAX(CASE WHEN "minor_category" = (SELECT "minor_category"
                                          FROM top5_2008 WHERE rn = 1)
                 THEN pct_share END) AS "CATEGORY_1",

        MAX(CASE WHEN "minor_category" = (SELECT "minor_category"
                                          FROM top5_2008 WHERE rn = 2)
                 THEN pct_share END) AS "CATEGORY_2",

        MAX(CASE WHEN "minor_category" = (SELECT "minor_category"
                                          FROM top5_2008 WHERE rn = 3)
                 THEN pct_share END) AS "CATEGORY_3",

        MAX(CASE WHEN "minor_category" = (SELECT "minor_category"
                                          FROM top5_2008 WHERE rn = 4)
                 THEN pct_share END) AS "CATEGORY_4",

        MAX(CASE WHEN "minor_category" = (SELECT "minor_category"
                                          FROM top5_2008 WHERE rn = 5)
                 THEN pct_share END) AS "CATEGORY_5"

FROM    percentages
GROUP BY "year"
ORDER BY "year";