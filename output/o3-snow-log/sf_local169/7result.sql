WITH terms AS (
    SELECT 
        "id_bioguide",
        TO_DATE("term_start")                                   AS start_date,
        COALESCE(TO_DATE("term_end"), '9999-12-31')             AS end_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
),
first_terms AS (
    SELECT 
        "id_bioguide",
        MIN(start_date)                                         AS first_term_start
    FROM terms
    GROUP BY "id_bioguide"
),
cohort AS (
    -- legislators whose very first term begins within the requested window
    SELECT *
    FROM first_terms
    WHERE first_term_start BETWEEN '1917-01-01' AND '1999-12-31'
),
cohort_size AS (
    SELECT COUNT(*) AS total FROM cohort
),
periods AS (
    -- generate the 20 yearly checkpoints (years 1–20 after start)
    SELECT SEQ4() + 1 AS period
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),
retention_counts AS (
    -- count how many of the cohort are still in office on 31-Dec of each year
    SELECT 
        p.period,
        COUNT(DISTINCT c."id_bioguide")                       AS retained_count
    FROM cohort            AS c
    CROSS JOIN periods     AS p
    JOIN terms             AS t
          ON t."id_bioguide" = c."id_bioguide"
         AND DATEFROMPARTS( YEAR(c.first_term_start) + p.period, 12, 31 )
             BETWEEN t.start_date AND t.end_date
    GROUP BY p.period
),
final AS (
    -- calculate retention rates and ensure every period appears
    SELECT
        p.period,
        COALESCE(r.retained_count, 0)                       AS retained_count,
        cs.total                                            AS cohort_size,
        COALESCE(r.retained_count, 0) / cs.total::FLOAT     AS retention_rate
    FROM periods p
    CROSS JOIN cohort_size cs
    LEFT JOIN retention_counts r ON p.period = r.period
)
SELECT
    period,
    ROUND(retention_rate, 4) AS retention_rate
FROM final
ORDER BY period;