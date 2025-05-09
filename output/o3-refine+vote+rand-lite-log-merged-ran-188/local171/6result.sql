WITH dec31 AS (
    /* All December-31 dates available in the calendar table */
    SELECT date
    FROM legislation_date_dim
    WHERE month_name = 'December'
      AND day_of_month = 31
),
la_men AS (
    /* Male legislators who have served Louisiana in any term */
    SELECT DISTINCT l.id_bioguide
    FROM legislators         AS l
    JOIN legislators_terms   AS t
      ON l.id_bioguide = t.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
),
first_term AS (
    /* Earliest term_start for each of those legislators */
    SELECT t.id_bioguide,
           MIN(t.term_start) AS first_term_start
    FROM legislators_terms AS t
    JOIN la_men            AS m USING (id_bioguide)
    GROUP BY t.id_bioguide
),
service_on_dec31 AS (
    /* Each December-31 on which the legislator was in office */
    SELECT t.id_bioguide,
           d.date,
           CAST(substr(d.date,1,4) AS INT) -
           CAST(substr(f.first_term_start,1,4) AS INT) AS years_elapsed
    FROM legislators_terms AS t
    JOIN la_men           AS m USING (id_bioguide)
    JOIN dec31            AS d
      ON d.date BETWEEN t.term_start AND t.term_end
    JOIN first_term       AS f USING (id_bioguide)
),
filtered AS (
    /* Keep only rows where service length is >30 and <50 years */
    SELECT id_bioguide,
           years_elapsed
    FROM service_on_dec31
    WHERE years_elapsed > 30
      AND years_elapsed < 50
)
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS legislators_active
FROM filtered
GROUP BY years_elapsed
ORDER BY years_elapsed;