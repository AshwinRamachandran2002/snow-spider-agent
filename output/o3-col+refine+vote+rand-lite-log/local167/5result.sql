WITH first_terms AS (
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms lt
    JOIN legislators l
      ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND lt.term_number = (
          SELECT MIN(term_number)
          FROM legislators_terms
          WHERE id_bioguide = lt.id_bioguide
      )
),
dec31_qualifiers AS (
    SELECT DISTINCT id_bioguide
    FROM legislators_terms
    WHERE date(term_end) >= date(substr(term_start, 1, 4) || '-12-31')
)
SELECT ft.state   AS top_state_abbrev,
       COUNT(*)   AS female_legislators_count
FROM   first_terms      ft
JOIN   dec31_qualifiers dq USING (id_bioguide)
GROUP BY ft.state
ORDER BY female_legislators_count DESC
LIMIT 1;