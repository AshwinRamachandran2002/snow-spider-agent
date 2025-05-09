/* 1. Identify the 5 minor-crime categories that account for the
      highest number of offences in 2008.                                   */
/* 2. For every year, work out the total crime count and the counts
      for those 5 categories.                                               */
/* 3. Convert the counts into percentage shares (rounded to 2 d.p.).        */
/* 4. Pivot so each year is one row and the five categories are columns.    */

WITH top5 AS (                                            -- step-1
    SELECT "minor_category"
    FROM   LONDON.LONDON_CRIME."CRIME_BY_LSOA"
    WHERE  "year" = 2008
    GROUP  BY "minor_category"
    ORDER  BY SUM("value") DESC NULLS LAST
    LIMIT  5
),
year_totals AS (                                          -- step-2a
    SELECT "year",
           SUM("value") AS year_total
    FROM   LONDON.LONDON_CRIME."CRIME_BY_LSOA"
    GROUP  BY "year"
),
cat_totals AS (                                           -- step-2b
    SELECT c."year",
           c."minor_category",
           SUM(c."value") AS cat_total
    FROM   LONDON.LONDON_CRIME."CRIME_BY_LSOA" c
           JOIN top5 t
             ON c."minor_category" = t."minor_category"
    GROUP  BY c."year", c."minor_category"
),
percentages AS (                                          -- step-3
    SELECT ct."year",
           ct."minor_category",
           ROUND( (ct.cat_total / yt.year_total) * 100 , 2 ) AS pct_share
    FROM   cat_totals ct
           JOIN year_totals yt
             ON ct."year" = yt."year"
)
SELECT *
FROM   percentages                                         -- step-4
PIVOT (
       MAX(pct_share)                                      -- value to show
       FOR "minor_category" IN (ANY)                       -- five columns
)
ORDER BY "year";