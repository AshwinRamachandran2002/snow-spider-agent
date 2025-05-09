WITH first_terms AS (   -- 1.  first term start for every legislator / state
    SELECT 
        lt."id_bioguide",
        MIN(TRY_TO_DATE(lt."term_start"))              AS "first_start",
        UPPER(TRIM(l."gender"))                        AS "gender",
        lt."state"                                     AS "state"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS  lt
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS        l
          ON lt."id_bioguide" = l."id_bioguide"
    GROUP BY lt."id_bioguide", UPPER(TRIM(l."gender")), lt."state"
),  

intervals AS (         -- 2. required checkpoints (years after first start)
    SELECT 0 AS diff UNION ALL 
    SELECT 2 UNION ALL 
    SELECT 4 UNION ALL 
    SELECT 6 UNION ALL 
    SELECT 8 UNION ALL 
    SELECT 10
),  

reference_dates AS (   -- 3.  31-Dec of the checkpoint year for every legislator
    SELECT 
        ft."id_bioguide",
        ft."gender",
        ft."state",
        i.diff,
        TO_DATE(TO_CHAR(DATEADD(year, i.diff, ft."first_start"), 'YYYY')||'-12-31') AS ref_date
    FROM first_terms ft
    CROSS JOIN intervals i
),  

service_spans AS (     -- 4.  keep rows where the legislator is serving on that ref_date
    SELECT DISTINCT
        rd."id_bioguide",
        rd."gender",
        rd."state",
        rd.diff
    FROM reference_dates rd
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
          ON lt."id_bioguide" = rd."id_bioguide"
    WHERE rd.ref_date BETWEEN 
          TRY_TO_DATE(lt."term_start")
          AND COALESCE(TRY_TO_DATE(NULLIF(lt."term_end", '')), TO_DATE('9999-12-31'))
),  

survivor_counts AS (   -- 5.  how many from the original cohort survive at each checkpoint
    SELECT 
        "state",
        "gender",
        diff,
        COUNT(DISTINCT "id_bioguide") AS survivors
    FROM service_spans
    GROUP BY "state", "gender", diff
),  

gender_valid AS (      -- 6.  states / gender that have non-zero survivors at ALL 6 checkpoints
    SELECT 
        "state",
        "gender"
    FROM survivor_counts
    GROUP BY "state", "gender"
    HAVING COUNT(DISTINCT diff) = 6        -- all 6 intervals present
       AND MIN(survivors)       > 0        -- non-zero at each interval
),  

states_both AS (       -- 7.  states where BOTH male and female pass the test
    SELECT "state"
    FROM gender_valid
    WHERE "gender" IN ('M','F')            -- keep only Male / Female cohorts
    GROUP BY "state"
    HAVING COUNT(DISTINCT "gender") = 2
)  

-- 8. final result
SELECT "state"
FROM states_both
ORDER BY "state";