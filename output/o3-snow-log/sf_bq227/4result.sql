/*  Annual percentage shares (rounded to 2 dp) of the five most common
    2008 minor-crime categories, one result-row per year               */

WITH top5 AS (               -- 1. top-5 “minor_category” in 2008
    SELECT "minor_category"
    FROM   LONDON.LONDON_CRIME.CRIME_BY_LSOA
    WHERE  "year" = 2008
    GROUP  BY "minor_category"
    ORDER  BY SUM("value") DESC
    LIMIT  5
),
year_totals AS (             -- 2. total crimes per year (all categories)
    SELECT "year",
           SUM("value") AS year_total
    FROM   LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP  BY "year"
),
cat_year_totals AS (         -- 3. yearly totals for only those 5 categories
    SELECT c."year",
           c."minor_category",
           SUM(c."value") AS cat_total
    FROM   LONDON.LONDON_CRIME.CRIME_BY_LSOA c
           JOIN top5 t ON c."minor_category" = t."minor_category"
    GROUP  BY c."year", c."minor_category"
),
percentages AS (             -- 4. convert to % share of that year’s total
    SELECT cy."year",
           cy."minor_category",
           ROUND( (cy.cat_total / yt.year_total) * 100, 2 ) AS pct_share
    FROM   cat_year_totals cy
           JOIN year_totals yt USING ("year")
)
-- 5. one row per year, showing each of the five categories and its % share
SELECT  "year",
        OBJECT_AGG("minor_category", pct_share) 
          AS top5_minor_category_percentage_shares
FROM    percentages
GROUP   BY "year"
ORDER   BY "year";