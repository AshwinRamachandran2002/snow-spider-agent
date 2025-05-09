WITH counts AS (          -- 1. number of crashes per cause & year
    SELECT ci.db_year  AS year,
           c.pcf_violation_category AS cause,
           COUNT(*)    AS cnt
    FROM   collisions  AS c
    JOIN   case_ids    AS ci ON ci.case_id = c.case_id
    WHERE  c.pcf_violation_category IS NOT NULL
    GROUP  BY ci.db_year, c.pcf_violation_category
),

ranked AS (               -- 2. rank causes within each year
    SELECT year,
           cause,
           cnt,
           ROW_NUMBER() OVER (PARTITION BY year
                              ORDER BY cnt DESC, cause) AS rn
    FROM   counts
),

top2 AS (                 -- 3. keep the two most common causes per year
    SELECT year,
           GROUP_CONCAT(cause, '|') AS top2_causes   -- ordered by rn (1 then 2)
    FROM  (
        SELECT year, cause, rn
        FROM   ranked
        WHERE  rn <= 2
        ORDER  BY year, rn
    )
    GROUP BY year
),

repeated_sets AS (        -- 4. find cause‑pairs that appear in >1 year
    SELECT top2_causes
    FROM   top2
    GROUP  BY top2_causes
    HAVING COUNT(*) > 1
)

-- 5. years whose two leading causes differ from every other year
SELECT year
FROM   top2
WHERE  top2_causes NOT IN (SELECT top2_causes FROM repeated_sets)
ORDER  BY year;