WITH first_terms AS (          -- each male Louisiana legislator’s first term-start
    SELECT lt.id_bioguide,
           MIN(lt.term_start) AS first_term_start
    FROM legislators_terms lt
    JOIN legislators l
      ON l.id_bioguide = lt.id_bioguide
    WHERE lt.state = 'LA'
      AND l.gender = 'M'
    GROUP BY lt.id_bioguide
),
years AS (                     -- the set 31 … 49
    SELECT 31 AS n UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
    UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
    UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45
    UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49
),
dec31_candidates AS (          -- candidate 31-49-year “Dec 31” dates per legislator
    SELECT ft.id_bioguide,
           y.n                            AS years_elapsed,
           (CAST(substr(ft.first_term_start,1,4) AS INTEGER) + y.n) || '-12-31' AS dec31_date
    FROM first_terms ft
    CROSS JOIN years y
),
active_on_dec31 AS (           -- keep only those dates that fall inside a term
    SELECT DISTINCT d.years_elapsed,
                    d.id_bioguide
    FROM dec31_candidates d
    JOIN legislators_terms lt
      ON lt.id_bioguide = d.id_bioguide
     AND lt.state       = 'LA'
     AND d.dec31_date BETWEEN lt.term_start AND lt.term_end
)
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS legislators_active
FROM   active_on_dec31
GROUP  BY years_elapsed
ORDER  BY years_elapsed;