WITH RECURSIVE
    /* 1 – 20 year offsets */
    years(n) AS (
        SELECT 1
        UNION ALL
        SELECT n + 1 FROM years WHERE n < 20
    ),

    /* Legislators whose very first term began between 1917‑01‑01 and 1999‑12‑31 */
    cohort AS (
        SELECT id_bioguide,
               MIN(term_start) AS first_start
        FROM legislators_terms
        GROUP BY id_bioguide
        HAVING DATE(first_start) BETWEEN '1917-01-01' AND '1999-12-31'
    ),

    /* Build one row per legislator per offset year with the 31‑Dec check‑date  */
    cohort_years AS (
        SELECT c.id_bioguide,
               y.n           AS year_offset,
               DATE(
                   STRFTIME('%Y', c.first_start) || '-12-31',
                   '+' || (y.n - 1) || ' years'
               )             AS check_date
        FROM cohort c
        CROSS JOIN years y
    ),

    /* How many of the cohort are still serving on each 31‑Dec date? */
    retained AS (
        SELECT cy.year_offset,
               COUNT(DISTINCT cy.id_bioguide) AS in_office
        FROM cohort_years  cy
        JOIN legislators_terms lt
              ON lt.id_bioguide = cy.id_bioguide
             AND DATE(lt.term_start) <= cy.check_date
             AND DATE(lt.term_end)   >= cy.check_date
        GROUP BY cy.year_offset
    ),

    cohort_size AS ( SELECT COUNT(*) AS total FROM cohort )

/* Final retention rate for each of the first 20 years */
SELECT
       y.n AS year_since_start,
       ROUND( COALESCE(r.in_office, 0) * 1.0 / c.total, 4) AS retention_rate
FROM years        y
CROSS JOIN cohort_size c
LEFT JOIN retained r ON r.year_offset = y.n
ORDER BY y.n;