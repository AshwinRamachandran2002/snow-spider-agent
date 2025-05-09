WITH RECURSIVE
    -- 1. Generate integers 0 … 19 for the 20 yearly checkpoints
    numbers(n) AS (
        SELECT 0
        UNION ALL
        SELECT n + 1 FROM numbers WHERE n + 1 < 20
    ),

    -- 2. Identify the cohort that began service between 1917-01-01 and 1999-12-31
    cohort AS (
        SELECT lt."id_bioguide",
               MIN(DATE(lt."term_start")) AS first_start
        FROM   "legislators_terms" lt
        GROUP  BY lt."id_bioguide"
        HAVING first_start BETWEEN '1917-01-01' AND '1999-12-31'
    ),

    -- 3. Cohort size for rate calculation
    cohort_size AS (
        SELECT COUNT(*) AS size FROM cohort
    ),

    -- 4. Build the 31-Dec evaluation date for each legislator & checkpoint
    eval_dates AS (
        SELECT c."id_bioguide",
               n,
               DATE(
                   strftime('%Y', DATE(c.first_start, '+' || n || ' years')) || '-12-31'
               ) AS eval_date
        FROM   cohort c
        CROSS  JOIN numbers
    ),

    -- 5. Keep (legislator, checkpoint) pairs where the legislator is still serving
    active AS (
        SELECT DISTINCT e.n,
               e."id_bioguide"
        FROM   eval_dates e
        JOIN   "legislators_terms" lt
               ON lt."id_bioguide" = e."id_bioguide"
              AND DATE(lt."term_start")                       <= e.eval_date
              AND DATE(COALESCE(lt."term_end", '9999-12-31')) >= e.eval_date
    ),

    -- 6. Count how many are active at each checkpoint
    retention_counts AS (
        SELECT n,
               COUNT(DISTINCT "id_bioguide") AS still_in_office
        FROM   active
        GROUP  BY n
    )

-- 7. Calculate the retention rate for each of the 20 years
SELECT
       numbers.n + 1 AS year_number,
       ROUND(
             1.0 * COALESCE(retention_counts.still_in_office, 0)
           / cohort_size.size
       , 4) AS retention_rate
FROM   numbers
LEFT   JOIN retention_counts USING (n)
CROSS  JOIN cohort_size
ORDER  BY year_number;