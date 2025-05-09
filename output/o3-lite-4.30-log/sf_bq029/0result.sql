WITH ca_inventor_counts AS (
    SELECT
        p."publication_number",
        FLOOR(p."publication_date" / 10000)               AS pub_year,
        COUNT(inv.value)                                  AS inventor_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."inventor") inv
    WHERE p."country_code" = 'CA'
      AND p."publication_date" BETWEEN 19600101 AND 20201231
    GROUP BY p."publication_number",
             FLOOR(p."publication_date" / 10000)
    HAVING COUNT(inv.value) > 0
),
period_stats AS (
    SELECT
        1960 + 5 * FLOOR((pub_year - 1960) / 5)           AS five_year_period,
        COUNT(*)                                          AS total_patent_publications,
        AVG(inventor_cnt)                                 AS avg_inventors_per_patent
    FROM ca_inventor_counts
    GROUP BY five_year_period
)
SELECT
    five_year_period,
    ROUND(avg_inventors_per_patent, 4)                    AS avg_inventors_per_patent,
    total_patent_publications
FROM period_stats
ORDER BY five_year_period;