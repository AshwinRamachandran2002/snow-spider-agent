WITH cohort AS (
    /* all legislators whose very first term started between 1917-01-01 and 1999-12-31 */
    SELECT "id_bioguide",
           MIN("term_start") AS first_start
    FROM   "legislators_terms"
    GROUP  BY "id_bioguide"
    HAVING DATE(first_start) BETWEEN '1917-01-01' AND '1999-12-31'
),
years AS (                        -- helper list of the 20 observation years
    SELECT 0 AS y UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
    SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
    SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL
    SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL
    SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL
    SELECT 18 UNION ALL SELECT 19
),
checkpoints AS (                  -- December-31 checkpoint for every (legislator, year_offset)
    SELECT c."id_bioguide",
           y.y,
           DATE(substr(c.first_start,1,4) || '-12-31', '+' || y.y || ' years') AS chk_date
    FROM   cohort c
    CROSS JOIN years y
),
stats AS (                        -- who is still in office on that checkpoint date?
    SELECT  y,
            COUNT(DISTINCT cp."id_bioguide")                                            AS cohort_total,
            COUNT(DISTINCT CASE
                   WHEN lt."id_bioguide" IS NOT NULL THEN cp."id_bioguide"
                 END)                                                                   AS retained
    FROM   checkpoints cp
    LEFT JOIN "legislators_terms" lt
           ON lt."id_bioguide" = cp."id_bioguide"
          AND DATE(lt."term_start") <= cp.chk_date
          AND DATE(COALESCE(lt."term_end",'9999-12-31')) >= cp.chk_date
    GROUP  BY y
)
SELECT  y AS "years_after_first_term",
        ROUND(1.0 * retained / cohort_total, 4) AS "annual_retention_rate"
FROM    stats
ORDER  BY y;