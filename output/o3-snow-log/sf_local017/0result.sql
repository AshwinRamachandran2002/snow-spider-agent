WITH "YEARLY_COUNTS" AS (      -- how often each cause appears every year
    SELECT
        ci."db_year",
        c."pcf_violation_category"        AS "cause",
        COUNT(*)                          AS "cnt"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"  c
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"    ci
          ON c."case_id" = ci."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY ci."db_year", c."pcf_violation_category"
), 
"TOP_TWO" AS (                 -- rank causes inside each year
    SELECT
        "db_year",
        "cause",
        "cnt",
        DENSE_RANK() OVER (PARTITION BY "db_year" 
                           ORDER BY "cnt" DESC NULLS LAST) AS "rnk"
    FROM "YEARLY_COUNTS"
), 
"TOP_TWO_FILTERED" AS (        -- keep only the 2 most common causes for every year
    SELECT "db_year", "cause", "cnt"
    FROM   "TOP_TWO"
    WHERE  "rnk" <= 2
), 
"YEAR_SETS" AS (               -- turn those two causes into an ordered, comma-separated set
    SELECT
        "db_year",
        LISTAGG("cause", ',') 
            WITHIN GROUP (ORDER BY "cnt" DESC NULLS LAST, "cause") AS "cause_pair"
    FROM "TOP_TWO_FILTERED"
    GROUP BY "db_year"
), 
"UNIQUE_SETS" AS (             -- find cause-pairs that occur in exactly one year
    SELECT "cause_pair"
    FROM   "YEAR_SETS"
    GROUP BY "cause_pair"
    HAVING COUNT(*) = 1
)
SELECT y."db_year"             -- final answer: years whose top-2 causes differ from all others
FROM   "YEAR_SETS"  y
JOIN   "UNIQUE_SETS" u
       ON y."cause_pair" = u."cause_pair"
ORDER BY y."db_year";