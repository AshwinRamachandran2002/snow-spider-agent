/*  Annual retention of legislators whose very first term began
    between 1917-01-01 and 1999-12-31.
    For every legislator in that cohort we look, for each of the
    first 20 years after their own start year, whether he/she still
    held at least one term that includes 31-Dec of that year.
*/
WITH terms AS (          -- all terms with proper DATE types
    SELECT
        "id_bioguide"                               AS id,
        TO_DATE("term_start")                       AS term_start,
        TO_DATE("term_end")                         AS term_end
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
),
cohort AS (             -- legislators whose FIRST term is in the window
    SELECT
        id,
        MIN(term_start)  AS first_start
    FROM terms
    GROUP BY id
    HAVING MIN(term_start) BETWEEN '1917-01-01' AND '1999-12-31'
),
periods AS (            -- the twenty year-offsets we must report
    SELECT seq4() + 1 AS year_offset          -- 1 … 20
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),
cohort_size AS (        -- denominator for the retention rate
    SELECT COUNT(*) AS total_members FROM cohort
),
retention AS (          -- how many of the cohort are still in office
    SELECT
        p.year_offset,
        COUNT(DISTINCT              -- count only if a covering term exists
              CASE
                  WHEN t.id IS NOT NULL THEN c.id
              END)      AS members_retained
    FROM periods  p
    CROSS JOIN cohort  c
    LEFT JOIN terms   t
           ON t.id = c.id
          AND t.term_start
                 <= DATE_FROM_PARTS(YEAR(c.first_start)+p.year_offset,12,31)
          AND ( t.term_end IS NULL
                OR t.term_end
                   >= DATE_FROM_PARTS(YEAR(c.first_start)+p.year_offset,12,31) )
    GROUP BY p.year_offset
)
SELECT
    r.year_offset             AS "year_since_start",
    ROUND(
        r.members_retained / cs.total_members
        , 4)                  AS "retention_rate"
FROM retention     r
CROSS JOIN cohort_size cs
ORDER BY r.year_offset;