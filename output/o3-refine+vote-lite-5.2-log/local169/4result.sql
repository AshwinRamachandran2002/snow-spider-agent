WITH first_terms AS (
    /* Legislators whose VERY FIRST term started between 1917‑01‑01 and 1999‑12‑31 */
    SELECT
        id_bioguide,
        MIN(term_start)              AS first_start,
        CAST(strftime('%Y', MIN(term_start)) AS INTEGER) AS start_year
    FROM legislators_terms
    WHERE term_start BETWEEN '1917-01-01' AND '1999-12-31'
    GROUP BY id_bioguide
),
/* Cohort size is fixed for every calculation */
cohort AS (
    SELECT id_bioguide, start_year FROM first_terms
),
/* Build integers 1 … 20 (year offsets after the initial start date) */
numbers(offset) AS (
    SELECT 1
    UNION ALL
    SELECT offset + 1 FROM numbers WHERE offset < 20
),
/* For every legislator and every offset, build the 31‑Dec date to test */
dates AS (
    SELECT
        c.id_bioguide,
        n.offset,
        (c.start_year + n.offset)                      AS yr,
        (c.start_year + n.offset) || '-12-31'          AS date_of_interest
    FROM cohort c
    CROSS JOIN numbers n
),
/* Find who is still in office on that 31‑Dec date */
in_office AS (
    SELECT
        d.offset,
        d.id_bioguide
    FROM dates d
    JOIN legislators_terms lt
         ON lt.id_bioguide = d.id_bioguide
        AND lt.term_start <= d.date_of_interest
        AND COALESCE(lt.term_end, '9999-12-31') >= d.date_of_interest
    GROUP BY d.offset, d.id_bioguide
),
/* Count retained legislators for each offset and compute the rate */
retention AS (
    SELECT
        n.offset                                   AS year_after_start,
        COUNT(DISTINCT io.id_bioguide)             AS retained,
        (SELECT COUNT(*) FROM cohort)              AS cohort_size
    FROM numbers n
    LEFT JOIN in_office io
           ON io.offset = n.offset
    GROUP BY n.offset
)
SELECT
    year_after_start,         -- 1 … 20
    retained,                 -- head‑count still serving
    cohort_size,              -- original cohort size
    ROUND(1.0 * retained / cohort_size, 4) AS retention_rate
FROM retention
ORDER BY year_after_start;