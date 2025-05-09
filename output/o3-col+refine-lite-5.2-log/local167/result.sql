WITH female_with_dec31 AS (
    -- Female legislators who had ANY term that included a Dec 31
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms AS lt
    JOIN legislators AS l
      ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND (
            CAST(substr(lt.term_end ,1,4) AS INTEGER)  >  CAST(substr(lt.term_start,1,4) AS INTEGER)  -- spans multiple years
         OR (substr(lt.term_end ,1,4) =  substr(lt.term_start,1,4)                                    -- same‑year term reaching ≥ Dec 31
             AND substr(lt.term_end ,6,5) >= '12-31')
          )
),
first_terms AS (
    -- Each qualifying legislator’s FIRST term (term_number = 0)
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms AS lt
    WHERE lt.term_number = 0
      AND lt.id_bioguide IN (SELECT id_bioguide FROM female_with_dec31)
)
SELECT state        AS state_abbrev,
       COUNT(*)     AS female_legislator_cnt
FROM   first_terms
GROUP  BY state
ORDER  BY female_legislator_cnt DESC
LIMIT 1;