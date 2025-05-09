WITH first_term AS (
    -- each legislator’s earliest service date
    SELECT l."id_bioguide",
           l."gender",
           MIN(DATE(lt."term_start")) AS first_start
    FROM   "legislators"        AS l
    JOIN   "legislators_terms"  AS lt
           ON l."id_bioguide" = lt."id_bioguide"
    WHERE  l."gender" IN ('M','F')
    GROUP  BY l."id_bioguide"
),
targets AS (
    -- calendar checkpoints at 0,2,4,6,8,10 yrs after first_start
    SELECT ft.*,
           CAST(STRFTIME('%Y', first_start) AS INTEGER)       AS y0,
           CAST(STRFTIME('%Y', first_start) AS INTEGER) + 2   AS y2,
           CAST(STRFTIME('%Y', first_start) AS INTEGER) + 4   AS y4,
           CAST(STRFTIME('%Y', first_start) AS INTEGER) + 6   AS y6,
           CAST(STRFTIME('%Y', first_start) AS INTEGER) + 8   AS y8,
           CAST(STRFTIME('%Y', first_start) AS INTEGER) + 10  AS y10
    FROM   first_term ft
),
retention AS (
    -- for each legislator, was he/she in office on each checkpoint?
    SELECT  t."id_bioguide",
            t."gender",
            lt."state",
            MAX(CASE WHEN DATE(t.y0  || '-12-31') BETWEEN lt."term_start" AND lt."term_end" THEN 1 ELSE 0 END)  AS r0,
            MAX(CASE WHEN DATE(t.y2  || '-12-31') BETWEEN lt."term_start" AND lt."term_end" THEN 1 ELSE 0 END)  AS r2,
            MAX(CASE WHEN DATE(t.y4  || '-12-31') BETWEEN lt."term_start" AND lt."term_end" THEN 1 ELSE 0 END)  AS r4,
            MAX(CASE WHEN DATE(t.y6  || '-12-31') BETWEEN lt."term_start" AND lt."term_end" THEN 1 ELSE 0 END)  AS r6,
            MAX(CASE WHEN DATE(t.y8  || '-12-31') BETWEEN lt."term_start" AND lt."term_end" THEN 1 ELSE 0 END)  AS r8,
            MAX(CASE WHEN DATE(t.y10 || '-12-31') BETWEEN lt."term_start" AND lt."term_end" THEN 1 ELSE 0 END)  AS r10
    FROM    targets            AS t
    JOIN    "legislators_terms" AS lt
            ON lt."id_bioguide" = t."id_bioguide"
    GROUP   BY t."id_bioguide", lt."state"
),
state_gender_pass AS (
    -- keep gender-state pairs whose cohort has >0 members at every checkpoint
    SELECT  "state",
            "gender"
    FROM    retention
    GROUP   BY "state", "gender"
    HAVING  SUM(r0)  > 0
       AND  SUM(r2)  > 0
       AND  SUM(r4)  > 0
       AND  SUM(r6)  > 0
       AND  SUM(r8)  > 0
       AND  SUM(r10) > 0
)
-- states where both male and female cohorts satisfy the rule
SELECT DISTINCT m."state"
FROM   state_gender_pass AS m
JOIN   state_gender_pass AS f
       ON m."state" = f."state"
WHERE  m."gender" = 'M'
  AND  f."gender" = 'F'
ORDER BY m."state";