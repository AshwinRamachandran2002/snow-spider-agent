WITH first_term AS (
    -- first term (earliest start) for every male legislator from Louisiana
    SELECT lt.id_bioguide,
           MIN(lt.term_start) AS first_start
    FROM legislators_terms  AS lt
    JOIN legislators        AS l
      ON l.id_bioguide = lt.id_bioguide
    WHERE lt.state = 'LA'
      AND l.gender = 'M'
    GROUP BY lt.id_bioguide
),
dec_31_dates AS (
    -- all December-31 calendar dates
    SELECT date
    FROM legislation_date_dim
    WHERE month_name = 'December'
      AND day_of_month = 31
),
candidate_snapshots AS (
    -- every Dec-31 that is 31-49 yrs after the legislator’s first term
    SELECT ft.id_bioguide,
           d.date,
           (CAST(strftime('%Y', d.date) AS INTEGER) -
            CAST(strftime('%Y', ft.first_start) AS INTEGER)) AS yrs_since_first_term
    FROM first_term     AS ft
    CROSS JOIN dec_31_dates AS d
    WHERE (CAST(strftime('%Y', d.date) AS INTEGER) -
           CAST(strftime('%Y', ft.first_start) AS INTEGER)) BETWEEN 31 AND 49
),
active_on_snapshot AS (
    -- keep only those Dec-31 dates when the legislator was actually in office
    SELECT cs.id_bioguide,
           cs.yrs_since_first_term
    FROM candidate_snapshots AS cs
    JOIN legislators_terms  AS t
      ON t.id_bioguide = cs.id_bioguide
     AND t.term_start <= cs.date
     AND t.term_end   >= cs.date
)
-- final counts: how many distinct legislators were active for each elapsed year bucket
SELECT yrs_since_first_term  AS years_elapsed,
       COUNT(DISTINCT id_bioguide) AS num_legislators_active
FROM active_on_snapshot
GROUP BY yrs_since_first_term
ORDER BY years_elapsed;