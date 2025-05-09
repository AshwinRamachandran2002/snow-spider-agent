WITH dec31_female AS (
    -- every female legislator who ever had a term that included Dec-31
    SELECT DISTINCT l.id_bioguide
    FROM legislators AS l
    JOIN legislators_terms AS lt
      ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND date(substr(lt.term_start,1,4) || '-12-31') <= lt.term_end
),
first_state AS (
    -- state a legislator represented in her very first term
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms AS lt
    JOIN (
        SELECT id_bioguide,
               MIN(term_start) AS first_start
        FROM legislators_terms
        GROUP BY id_bioguide
    ) AS fs
      ON fs.id_bioguide = lt.id_bioguide
     AND fs.first_start   = lt.term_start
)
SELECT fs.state              AS state_abbrev,
       COUNT(*)              AS female_legislator_count
FROM   dec31_female AS df
JOIN   first_state   AS fs
  ON   fs.id_bioguide = df.id_bioguide
GROUP  BY fs.state
ORDER  BY female_legislator_count DESC
LIMIT 1;