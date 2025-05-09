WITH RECURSIVE
    -- integers 31 … 49  (years elapsed >30 and <50)
    numbers(n) AS (
        SELECT 31
        UNION ALL
        SELECT n + 1 FROM numbers WHERE n < 49
    ),

    -- male legislators from Louisiana with the first date they ever started serving
    male_la AS (
        SELECT
            lt.id_bioguide,
            MIN( DATE(lt.term_start) ) AS first_start
        FROM legislators_terms lt
        JOIN legislators l
              ON l.id_bioguide = lt.id_bioguide
        WHERE l.gender = 'M'
          AND lt.state  = 'LA'
        GROUP BY lt.id_bioguide
    ),

    -- for every legislator, build the December‑31 date that is n years after his first term
    service_dates AS (
        SELECT
            m.id_bioguide,
            n                             AS years_elapsed,
            DATE( (CAST( strftime('%Y', m.first_start) AS INTEGER) + n) || '-12-31' ) AS target_date
        FROM male_la m
        JOIN numbers
    ),

    -- keep only the dates on which the legislator was actually in office
    active_on_dec31 AS (
        SELECT DISTINCT
            sd.id_bioguide,
            sd.years_elapsed
        FROM service_dates  sd
        JOIN legislators_terms lt
              ON lt.id_bioguide = sd.id_bioguide
             AND DATE(lt.term_start) <= sd.target_date
             AND (lt.term_end IS NULL OR DATE(lt.term_end) >= sd.target_date)
    )

-- final counts grouped by exact years elapsed since first term
SELECT
    years_elapsed,
    COUNT(DISTINCT id_bioguide) AS distinct_legislators
FROM active_on_dec31
GROUP BY years_elapsed
ORDER BY years_elapsed;