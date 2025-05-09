WITH cohort AS (   -- legislators whose FIRST term began 1917-01-01 – 1999-12-31
    SELECT
        "id_bioguide",
        MIN(TO_DATE("term_start"))      AS first_start
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    GROUP BY "id_bioguide"
    HAVING first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
seq AS (           -- the 20 yearly checkpoints   (1 … 20)
    SELECT SEQ4() + 1 AS rel_year
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),
checkpoints AS (   -- every legislator × every checkpoint date (= 20 rows each)
    SELECT
        c."id_bioguide",
        s.rel_year,
        DATE_FROM_PARTS( YEAR(c.first_start) + s.rel_year , 12 , 31 )  AS check_date
    FROM cohort c
    JOIN seq    s ON 1 = 1
),
active AS (        -- legislator is still in office on the checkpoint date
    SELECT DISTINCT
        p."id_bioguide",
        p.rel_year
    FROM checkpoints p
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
      ON p."id_bioguide" = t."id_bioguide"
     AND TO_DATE(t."term_start")                     <= p.check_date
     AND COALESCE(TRY_TO_DATE(t."term_end"), '9999-12-31') >= p.check_date
),
retained AS (      -- how many from the cohort remain for each relative-year
    SELECT
        rel_year,
        COUNT(DISTINCT "id_bioguide") AS retained_cnt
    FROM active
    GROUP BY rel_year
),
cohort_size AS (
    SELECT COUNT(DISTINCT "id_bioguide") AS total_cnt FROM cohort
)
SELECT
    s.rel_year                                            AS years_after_start,
    ROUND( COALESCE(r.retained_cnt, 0) / cs.total_cnt , 4 ) AS retention_rate
FROM seq s
CROSS JOIN cohort_size cs
LEFT JOIN retained r ON r.rel_year = s.rel_year
ORDER BY s.rel_year;