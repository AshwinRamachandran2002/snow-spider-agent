WITH first_terms AS (
    SELECT
        l.id_bioguide,
        CAST(SUBSTR(MIN(t.term_start), 1, 4) AS INTEGER) AS first_year
    FROM legislators_terms t
    JOIN legislators l
      ON l.id_bioguide = t.id_bioguide
    WHERE t.state = 'LA'
      AND l.gender = 'M'
    GROUP BY l.id_bioguide
),
nums(n) AS (
    SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL
    SELECT 35 UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL
    SELECT 39 UNION ALL SELECT 40 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL
    SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL
    SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49
),
anniv AS (
    SELECT
        f.id_bioguide,
        n.n AS years_since_first_term,
        (f.first_year + n.n) || '-12-31' AS target_date
    FROM first_terms f
    JOIN nums n
)
SELECT
    a.years_since_first_term,
    COUNT(DISTINCT a.id_bioguide) AS count_distinct_legislators
FROM anniv a
JOIN legislators_terms t
  ON t.id_bioguide = a.id_bioguide
 AND t.term_start <= a.target_date
 AND COALESCE(t.term_end, '9999-12-31') >= a.target_date
GROUP BY a.years_since_first_term
ORDER BY a.years_since_first_term;