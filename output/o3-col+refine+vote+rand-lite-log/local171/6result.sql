WITH
    -- 1.  All male legislators who have ever represented Louisiana
    male_la AS (
        SELECT DISTINCT l.id_bioguide
        FROM legislators         AS l
        JOIN legislators_terms   AS t  ON t.id_bioguide = l.id_bioguide
        WHERE l.gender = 'M'
          AND t.state  = 'LA'
    ),

    -- 2.  First calendar‐year each of those legislators entered office
    first_term AS (
        SELECT t.id_bioguide,
               CAST(strftime('%Y', MIN(t.term_start)) AS INTEGER) AS first_year
        FROM legislators_terms AS t
        JOIN male_la          USING (id_bioguide)
        GROUP BY t.id_bioguide
    ),

    -- 3.  Expand every term into the individual calendar-years it spans
    term_years(id_bioguide, yr, yr_end, term_start, term_end) AS (
        SELECT t.id_bioguide,
               CAST(strftime('%Y', t.term_start) AS INTEGER)        AS yr,
               CAST(strftime('%Y', t.term_end)   AS INTEGER)        AS yr_end,
               t.term_start,
               t.term_end
        FROM legislators_terms AS t
        JOIN male_la          USING (id_bioguide)
        UNION ALL
        SELECT id_bioguide,
               yr + 1,
               yr_end,
               term_start,
               term_end
        FROM term_years
        WHERE yr + 1 <= yr_end
    ),

    -- 4.  Keep only those calendar-years whose December 31 falls inside the term
    --     and are 31-49 years after the legislator’s first term
    dec31_active AS (
        SELECT ty.id_bioguide,
               ty.yr,
               ty.yr - ft.first_year AS years_elapsed
        FROM term_years  AS ty
        JOIN first_term  AS ft USING (id_bioguide)
        WHERE date(ty.yr || '-12-31') BETWEEN ty.term_start AND ty.term_end
          AND (ty.yr - ft.first_year) > 30     -- more than 30 years
          AND (ty.yr - ft.first_year) < 50     -- less than 50 years
    )

-- 5.  How many distinct legislators were active for each elapsed–year bucket?
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS num_legislators_active
FROM   dec31_active
GROUP  BY years_elapsed
ORDER  BY years_elapsed;