WITH female_legislators AS (
    SELECT id_bioguide
    FROM legislators
    WHERE lower(gender) LIKE 'f%'          -- keeps 'F', 'Female', etc.
), ------------------------------------------------------------------
dec31_ids AS (                           -- females with any term that
    SELECT DISTINCT lt.id_bioguide       -- ever included a Dec‑31 date
    FROM legislators_terms lt
    JOIN female_legislators fl
      ON fl.id_bioguide = lt.id_bioguide
    WHERE date(substr(lt.term_start,1,4) || '-12-31')
          <= date(lt.term_end)
), ------------------------------------------------------------------
first_term_start AS (                    -- each female’s very first term
    SELECT lt.id_bioguide,
           MIN(date(lt.term_start)) AS first_start
    FROM legislators_terms lt
    JOIN female_legislators fl
      ON fl.id_bioguide = lt.id_bioguide
    GROUP BY lt.id_bioguide
), ------------------------------------------------------------------
first_state AS (                         -- state represented in that
    SELECT fts.id_bioguide,              -- first term
           MIN(lt.state) AS state        -- (MIN resolves rare ties)
    FROM first_term_start fts
    JOIN legislators_terms lt
      ON lt.id_bioguide = fts.id_bioguide
     AND date(lt.term_start) = fts.first_start
    GROUP BY fts.id_bioguide
) -------------------------------------------------------------------
SELECT fs.state,
       COUNT(*) AS female_legislator_count
FROM first_state fs
JOIN dec31_ids d
  ON d.id_bioguide = fs.id_bioguide
GROUP BY fs.state
ORDER BY female_legislator_count DESC, fs.state
LIMIT 1;