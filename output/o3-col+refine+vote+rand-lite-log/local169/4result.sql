WITH RECURSIVE
    cohort AS (   -- legislators whose very first term began 1917-1999
        SELECT "id_bioguide",
               MIN("term_start") AS first_start
        FROM   "legislators_terms"
        GROUP  BY "id_bioguide"
        HAVING date(MIN("term_start")) BETWEEN '1917-01-01' AND '1999-12-31'
    ),
    cohort_size AS (              -- total members in the cohort
        SELECT COUNT(*) AS n FROM cohort
    ),
    years(y) AS (                 -- year offsets 0-19
        SELECT 0
        UNION ALL
        SELECT y + 1 FROM years WHERE y < 19
    )

SELECT
    y AS year_offset,
    ROUND(
        100.0 * COUNT(DISTINCT c."id_bioguide") / cs.n,
        4
    ) AS retention_rate_pct
FROM       years
LEFT JOIN  cohort              AS c
JOIN       "legislators_terms" AS t
           ON t."id_bioguide" = c."id_bioguide"
          -- legislator must be in office on Dec-31 of the offset year
          AND date(t."term_start") <= date(c.first_start,
                                           '+' || y || ' years',
                                           'start of year',
                                           '+11 months',
                                           '+30 days')   -- 31-Dec
          AND date(t."term_end")   >= date(c.first_start,
                                           '+' || y || ' years',
                                           'start of year',
                                           '+11 months',
                                           '+30 days')
CROSS JOIN cohort_size cs
GROUP BY y
ORDER BY y;