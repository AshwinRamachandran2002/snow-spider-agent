WITH inventor_count AS (
    SELECT
        p."publication_number",
        1960 + 5 * FLOOR((FLOOR(p."publication_date" / 10000) - 1960) / 5) AS "period_start_year",
        COUNT(f.value) AS "inventor_cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."inventor") AS f
    WHERE p."country_code" = 'CA'
      AND p."publication_date" BETWEEN 19600101 AND 20201231
    GROUP BY p."publication_number", p."publication_date"
),
period_stats AS (
    SELECT
        "period_start_year",
        CONCAT("period_start_year", '-', "period_start_year" + 4)       AS "five_year_period",
        ROUND(AVG("inventor_cnt"), 4)                                   AS "avg_inventors_per_patent",
        COUNT(*)                                                        AS "total_patent_publications"
    FROM inventor_count
    WHERE "inventor_cnt" > 0
    GROUP BY "period_start_year"
)
SELECT
    "five_year_period",
    "avg_inventors_per_patent",
    "total_patent_publications"
FROM period_stats
ORDER BY "period_start_year";