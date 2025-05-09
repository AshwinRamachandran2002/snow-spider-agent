/* -----------------------------------------------------------
   Annual percentage share (rounded to 2 dp) of the 2008 “top-5”
   minor-crime categories in London’s total crime count.
   ‑ Top-5 categories are chosen on their 2008 totals.
   ‑ One result-row per calendar year.
------------------------------------------------------------ */
WITH top5 AS (                               -- 1. The 2008 Top-5 minor categories
    SELECT
        "minor_category",
        ROW_NUMBER() OVER (ORDER BY SUM("value") DESC) AS rn
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
    WHERE "year" = 2008
    GROUP BY "minor_category"
    ORDER BY SUM("value") DESC
    LIMIT 5
),
yearly_totals AS (                           -- 2. Total crimes in each year
    SELECT
        "year",
        SUM("value") AS total_crimes
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP BY "year"
),
yearly_top5 AS (                             -- 3. Yearly totals for each of the top-5 categories
    SELECT
        c."year",
        SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5 WHERE rn = 1) THEN c."value" END) AS cat1_cnt,
        SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5 WHERE rn = 2) THEN c."value" END) AS cat2_cnt,
        SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5 WHERE rn = 3) THEN c."value" END) AS cat3_cnt,
        SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5 WHERE rn = 4) THEN c."value" END) AS cat4_cnt,
        SUM(CASE WHEN c."minor_category" = (SELECT "minor_category" FROM top5 WHERE rn = 5) THEN c."value" END) AS cat5_cnt
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA c
    GROUP BY c."year"
)
SELECT
    t."year",
    ROUND(100 * yt.cat1_cnt / t.total_crimes, 2) AS "TOP1_PCT",
    ROUND(100 * yt.cat2_cnt / t.total_crimes, 2) AS "TOP2_PCT",
    ROUND(100 * yt.cat3_cnt / t.total_crimes, 2) AS "TOP3_PCT",
    ROUND(100 * yt.cat4_cnt / t.total_crimes, 2) AS "TOP4_PCT",
    ROUND(100 * yt.cat5_cnt / t.total_crimes, 2) AS "TOP5_PCT"
FROM yearly_totals t
JOIN yearly_top5 yt
  ON yt."year" = t."year"
ORDER BY t."year";