/*  annual retention of legislators whose first term started between
    1917-01-01 and 1999-12-31, for the first 20 years after that start  */

WITH cohort AS (      -- every legislator’s first term start within the window
    SELECT
        "id_bioguide",
        MIN(TO_DATE("term_start")) AS first_start_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    GROUP BY "id_bioguide"
    HAVING first_start_date BETWEEN '1917-01-01' AND '1999-12-31'
),

term_ranges AS (      -- each term with a proper start / end date range
    SELECT
        "id_bioguide",
        TO_DATE("term_start")                                       AS term_start_date,
        COALESCE(TO_DATE(NULLIF("term_end", '')), '9999-12-31')     AS term_end_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
),

numbers AS (          -- 1 … 20 year offsets
    SELECT (SEQ4() + 1) AS year_number
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),

cohort_years AS (     -- one record per legislator per analysis year
    SELECT
        c."id_bioguide",
        n.year_number,
        DATE_FROM_PARTS(YEAR(c.first_start_date) + n.year_number, 12, 31) AS eval_date
    FROM cohort c
    CROSS JOIN numbers n
),

retention_flag AS (   -- flag whether legislator was still in office on eval_date
    SELECT
        cy.year_number,
        cy."id_bioguide",
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM term_ranges tr
                WHERE tr."id_bioguide" = cy."id_bioguide"
                  AND tr.term_start_date <= cy.eval_date
                  AND tr.term_end_date   >= cy.eval_date
            )
            THEN 1 ELSE 0
        END AS is_retained
    FROM cohort_years cy
)

SELECT
    year_number            AS years_after_start,
    ROUND(AVG(is_retained), 4)  AS retention_rate     -- proportion of cohort retained
FROM retention_flag
GROUP BY year_number
ORDER BY year_number;