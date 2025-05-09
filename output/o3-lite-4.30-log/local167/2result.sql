WITH dec31_qual_legislators AS (
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN legislators l
      ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND (
            CAST(substr(lt.term_end,1,4) AS INTEGER) >
            CAST(substr(lt.term_start,1,4) AS INTEGER)
         OR (
            CAST(substr(lt.term_end,1,4) AS INTEGER) =
            CAST(substr(lt.term_start,1,4) AS INTEGER)
            AND substr(lt.term_end,6,5) >= '12-31'
         )
      )
), first_term_overall AS (
    SELECT lt.id_bioguide,
           MIN(lt.term_start) AS first_start
    FROM legislators_terms lt
    JOIN dec31_qual_legislators q
      ON q.id_bioguide = lt.id_bioguide
    GROUP BY lt.id_bioguide
), first_state AS (
    SELECT f.id_bioguide,
           lt.state
    FROM first_term_overall f
    JOIN legislators_terms lt
      ON lt.id_bioguide = f.id_bioguide
     AND lt.term_start  = f.first_start
)
SELECT state AS state_abbreviation,
       COUNT(*) AS female_legislator_count
FROM first_state
GROUP BY state
ORDER BY female_legislator_count DESC,
         state
LIMIT 1;