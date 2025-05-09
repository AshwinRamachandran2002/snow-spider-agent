WITH top5 AS (   -- 1. five largest-volume minor categories in 2008
    SELECT "minor_category"
    FROM LONDON.LONDON_CRIME."CRIME_BY_LSOA"
    WHERE "year" = 2008
    GROUP BY "minor_category"
    ORDER BY SUM("value") DESC NULLS LAST
    LIMIT 5
),
year_totals AS (   -- 2. total crimes per year (all categories)
    SELECT "year",
           SUM("value") AS total_crimes
    FROM LONDON.LONDON_CRIME."CRIME_BY_LSOA"
    GROUP BY "year"
),
cat_year AS (      -- 3. yearly totals for the selected minor categories
    SELECT c."year",
           c."minor_category",
           SUM(c."value") AS cat_total
    FROM LONDON.LONDON_CRIME."CRIME_BY_LSOA" c
    JOIN top5 t
      ON c."minor_category" = t."minor_category"
    GROUP BY c."year", c."minor_category"
),
percentages AS (   -- 4. percentage share of each category per year
    SELECT
        cy."year",
        cy."minor_category",
        ROUND(100 * cy.cat_total / yt.total_crimes, 2) AS pct_share
    FROM cat_year  cy
    JOIN year_totals yt
      ON cy."year" = yt."year"
)
-- 5. pivot so each year is one row and the five categories are columns
SELECT *
FROM (
    SELECT "year",
           "minor_category",
           pct_share
    FROM percentages
) PIVOT (
    MAX(pct_share)
    FOR "minor_category" IN (SELECT "minor_category" FROM top5)   -- no ORDER BY here
)
ORDER BY "year";