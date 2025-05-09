WITH RECURSIVE
la_male AS (      -- male legislators who have represented Louisiana
    SELECT DISTINCT l.id_bioguide
    FROM legislators AS l
    JOIN legislators_terms AS t
      ON l.id_bioguide = t.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
),
first_term AS (   -- first term‑start date for each of those legislators
    SELECT t.id_bioguide,
           MIN(t.term_start) AS first_start
    FROM legislators_terms AS t
    JOIN la_male           AS lm
      ON t.id_bioguide = lm.id_bioguide
    GROUP BY t.id_bioguide
),
term_bounds AS (  -- start / end years of every term they served
    SELECT t.id_bioguide,
           CAST(strftime('%Y', t.term_start) AS INTEGER) AS start_year,
           CAST(strftime('%Y', t.term_end)   AS INTEGER) AS end_year
    FROM legislators_terms AS t
    JOIN la_male           AS lm
      ON t.id_bioguide = lm.id_bioguide
),
/* generate every calendar year covered by each term */
year_series(id_bioguide, yr, end_year) AS (
    SELECT id_bioguide, start_year, end_year
    FROM   term_bounds
    UNION ALL
    SELECT id_bioguide, yr + 1, end_year
    FROM   year_series
    WHERE  yr + 1 <= end_year
),
dec31_active AS (   -- keep only years where 31‑Dec falls inside a term
    SELECT DISTINCT ys.id_bioguide,
                    ys.yr
    FROM   year_series        AS ys
    JOIN   legislators_terms  AS t
           ON t.id_bioguide = ys.id_bioguide
          AND date(ys.yr || '-12-31')
              BETWEEN t.term_start AND t.term_end
),
elapsed AS (        -- years since first term
    SELECT da.id_bioguide,
           da.yr - CAST(strftime('%Y', ft.first_start) AS INTEGER)
               AS years_elapsed
    FROM   dec31_active AS da
    JOIN   first_term   AS ft
      ON   ft.id_bioguide = da.id_bioguide
)
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS legislators_count
FROM   elapsed
WHERE  years_elapsed > 30          -- more than 30 years
  AND  years_elapsed < 50          -- less than 50 years
GROUP  BY years_elapsed
ORDER  BY years_elapsed;