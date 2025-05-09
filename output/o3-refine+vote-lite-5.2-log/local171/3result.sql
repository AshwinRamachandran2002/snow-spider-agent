WITH RECURSIVE
    /* male legislators who have had at least one term from Louisiana */
    selected_terms AS (
        SELECT lt.id_bioguide,
               lt.term_start,
               lt.term_end
        FROM legislators_terms lt
        JOIN legislators l
          ON l.id_bioguide = lt.id_bioguide
        WHERE l.gender = 'M'          -- male
          AND lt.state  = 'LA'        -- Louisiana
    ),

    /* first (earliest) term‑start date for every such legislator */
    first_terms AS (
        SELECT id_bioguide,
               MIN(term_start) AS first_term_start
        FROM selected_terms
        GROUP BY id_bioguide
    ),

    /* expand every term into the individual calendar years it covers */
    years_per_term AS (
        -- anchor: first calendar year of each term
        SELECT id_bioguide,
               CAST(strftime('%Y', term_start) AS INTEGER) AS yr,
               term_start,
               term_end,
               CAST(strftime('%Y', term_end) AS INTEGER) AS last_yr
        FROM selected_terms
        UNION ALL
        -- recursive step: move to the next year while still in the term
        SELECT id_bioguide,
               yr + 1,
               term_start,
               term_end,
               last_yr
        FROM years_per_term
        WHERE yr + 1 <= last_yr
    ),

    /* keep only those years where the legislator was in office on 31‑Dec */
    dec31_active AS (
        SELECT DISTINCT y.id_bioguide,
               y.yr,
               f.first_term_start
        FROM years_per_term y
        JOIN first_terms f USING (id_bioguide)
        WHERE DATE(printf('%04d-12-31', y.yr))
              BETWEEN DATE(y.term_start) AND DATE(y.term_end)
    ),

    /* calculate years elapsed since the legislator’s first term */
    elapsed AS (
        SELECT id_bioguide,
               yr,
               (yr - CAST(strftime('%Y', first_term_start) AS INTEGER)) AS years_elapsed
        FROM dec31_active
        WHERE (yr - CAST(strftime('%Y', first_term_start) AS INTEGER)) > 30
          AND (yr - CAST(strftime('%Y', first_term_start) AS INTEGER)) < 50
    )

/* final result */
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS legislators_active_on_dec31
FROM   elapsed
GROUP  BY years_elapsed
ORDER  BY years_elapsed;