/* ----------------------------------------------------------------------------
   Annual retention for legislators whose FIRST term began between
   1917-01-01 and 1999-12-31.
   Retention is measured on 31-Dec of each of the first 20 years
   (Year-1 … Year-20) that follow a legislator’s initial term start.
   ---------------------------------------------------------------------------*/
WITH cohort AS (        -- legislators in the cohort and their first-ever start
    SELECT
        lt."id_bioguide"                         AS legislator_id ,
        MIN(TRY_TO_DATE(lt."term_start"))        AS first_term_start
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    GROUP BY lt."id_bioguide"
    HAVING first_term_start BETWEEN '1917-01-01' AND '1999-12-31'
),

cohort_size AS (        -- size of the cohort (denominator)
    SELECT COUNT(*) AS total FROM cohort
),

periods AS (            -- offsets 0 … 19  (== Year-1 … Year-20)
    SELECT seq4() AS offset_year
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),

retention AS (          -- for every offset, count legislators still in office
    SELECT
        p.offset_year + 1                                             AS year_number ,   -- 1 … 20
        SUM( CASE
                 WHEN EXISTS (       -- was the legislator in office on that 31-Dec ?
                     SELECT 1
                     FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
                     WHERE t."id_bioguide" = c.legislator_id
                       AND TRY_TO_DATE(t."term_start") 
                           <= DATE_FROM_PARTS( YEAR(c.first_term_start) + p.offset_year , 12 , 31 )
                       AND COALESCE(
                               TRY_TO_DATE(NULLIF(t."term_end" , '')) ,
                               TO_DATE('3000-12-31')                   -- treat open-ended terms
                           )
                           >= DATE_FROM_PARTS( YEAR(c.first_term_start) + p.offset_year , 12 , 31 )
                 )
                 THEN 1 ELSE 0
            END )                                                    AS retained_cnt
    FROM cohort  c
    CROSS JOIN periods p
    GROUP BY p.offset_year
)

SELECT
    r.year_number                           AS years_since_start ,   -- 1 … 20
    ROUND( r.retained_cnt / cs.total , 4 )  AS retention_rate        -- proportion retained
FROM retention r
CROSS JOIN cohort_size cs
ORDER BY r.year_number;