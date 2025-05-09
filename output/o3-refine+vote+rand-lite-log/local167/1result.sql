WITH female_terms AS (
    /* Female legislators’ terms that covered at least one Dec‑31 */
    SELECT lt.id_bioguide,
           lt.state,
           lt.term_start
    FROM legislators_terms lt
    JOIN legislators l
         ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND (
            CAST(substr(lt.term_end,1,4) AS INTEGER)  > CAST(substr(lt.term_start,1,4) AS INTEGER)
         OR (CAST(substr(lt.term_end,1,4) AS INTEGER) = CAST(substr(lt.term_start,1,4) AS INTEGER)
             AND substr(lt.term_end,6,5)              >= '12-31')
      )
),
first_state_per_legislator AS (
    /* For each legislator pick the state from her earliest qualifying term */
    SELECT id_bioguide,
           state
    FROM (
        SELECT id_bioguide,
               state,
               term_start,
               ROW_NUMBER() OVER (PARTITION BY id_bioguide ORDER BY term_start) AS rn
        FROM female_terms
    )
    WHERE rn = 1
),
state_counts AS (
    /* Count how many such legislators first represented each state */
    SELECT state,
           COUNT(*) AS female_legislators_count
    FROM first_state_per_legislator
    GROUP BY state
)
SELECT state,
       female_legislators_count
FROM state_counts
ORDER BY female_legislators_count DESC,
         state
LIMIT 1;