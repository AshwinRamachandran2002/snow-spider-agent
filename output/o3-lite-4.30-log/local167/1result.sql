WITH dec31_females AS (
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN legislators l ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND DATE(strftime('%Y', lt.term_start) || '-12-31')
          BETWEEN DATE(lt.term_start) AND DATE(lt.term_end)
),
first_term AS (
    SELECT lt.id_bioguide,
           lt.state,
           lt.term_start
    FROM legislators_terms lt
    JOIN dec31_females d ON d.id_bioguide = lt.id_bioguide
),
first_state AS (
    SELECT f1.id_bioguide,
           f1.state
    FROM first_term f1
    JOIN (
        SELECT id_bioguide, MIN(term_start) AS min_start
        FROM first_term
        GROUP BY id_bioguide
    ) f2 ON f1.id_bioguide = f2.id_bioguide 
        AND f1.term_start = f2.min_start
)
SELECT state AS state_abbreviation,
       COUNT(*) AS female_legislator_count
FROM first_state
GROUP BY state
ORDER BY female_legislator_count DESC
LIMIT 1;