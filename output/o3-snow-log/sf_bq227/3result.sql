WITH top_5_2008 AS (     -- 1. find the 5 largest-volume minor categories in 2008
    SELECT "minor_category"
    FROM   LONDON.LONDON_CRIME.CRIME_BY_LSOA
    WHERE  "year" = 2008
    GROUP  BY "minor_category"
    ORDER  BY SUM("value") DESC
    LIMIT  5
),
yearly_totals AS (       -- 2. total number of crimes in every year
    SELECT "year",
           SUM("value") AS total_crimes
    FROM   LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP  BY "year"
),
yearly_top5_totals AS (  -- 3. yearly totals for those 5 categories
    SELECT c."year",
           c."minor_category",
           SUM(c."value") AS category_crimes
    FROM   LONDON.LONDON_CRIME.CRIME_BY_LSOA  c
           JOIN top_5_2008 t
             ON c."minor_category" = t."minor_category"
    GROUP  BY c."year",
             c."minor_category"
),
yearly_percentages AS (  -- 4. convert to % share of that year’s overall crimes
    SELECT ytt."year",
           ytt."minor_category",
           ROUND( (ytt.category_crimes / yt.total_crimes) * 100, 2 ) AS pct_share
    FROM   yearly_top5_totals ytt
           JOIN yearly_totals yt
             ON ytt."year" = yt."year"
)
-- 5. one row per year; a VARIANT shows the five categories and their % shares
SELECT "year",
       OBJECT_AGG("minor_category", pct_share) AS percentage_shares
FROM   yearly_percentages
GROUP  BY "year"
ORDER  BY "year";