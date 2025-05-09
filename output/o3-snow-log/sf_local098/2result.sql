WITH clean_credits AS (                         -- 1) one row per actor-credit with a valid 4-digit year
    SELECT
        mc."PID",
        TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '\\d{4}')) AS yr
    FROM   "DB_IMDB"."DB_IMDB"."M_CAST"  mc
    JOIN   "DB_IMDB"."DB_IMDB"."MOVIE"   m  ON m."MID" = mc."MID"
    WHERE  TRY_TO_NUMBER(REGEXP_SUBSTR(m."year", '\\d{4}')) IS NOT NULL
),
year_gaps AS (                                  -- 2) gap between consecutive credits for each actor
    SELECT
        "PID",
        yr - LAG(yr) OVER (PARTITION BY "PID" ORDER BY yr) AS gap_years
    FROM clean_credits
),
max_gap AS (                                    -- 3) largest gap per actor (keep those ≤ 3)
    SELECT
        "PID",
        COALESCE(MAX(gap_years), 0) AS max_gap
    FROM year_gaps
    GROUP BY "PID"
    HAVING COALESCE(MAX(gap_years), 0) <= 3
)
SELECT COUNT(*) AS actors_without_4yr_gap       -- 4) final answer
FROM   max_gap;