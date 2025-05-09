WITH best_per_interest AS (
    /* 1.  Pick the month in which each interest category recorded its
           HIGHEST composition value                                  */
    SELECT  im.interest_id,
            im.month_year,          -- time in MM-YYYY format
            im.composition,
            mp.interest_name,
            ROW_NUMBER() OVER (
                PARTITION BY im.interest_id
                ORDER BY im.composition DESC,    -- choose the max
                         im._year, im._month     -- tie‑breaker
            ) AS rn
    FROM    interest_metrics AS im
    JOIN    interest_map     AS mp
           ON im.interest_id = mp.id
),
highest_composition AS (
    /* 2. Keep only that single “best month” row for every interest_id */
    SELECT month_year,
           interest_name,
           composition
    FROM   best_per_interest
    WHERE  rn = 1
),
/* 3. Top‑10 and Bottom‑10 by those peak composition values            */
top10 AS (
    SELECT 1                  AS grp,           -- for final ordering
           month_year,
           interest_name,
           composition,
           ROW_NUMBER() OVER (ORDER BY composition DESC, interest_name) AS seq
    FROM   highest_composition
    ORDER  BY composition DESC
    LIMIT 10
),
bottom10 AS (
    SELECT 2                  AS grp,
           month_year,
           interest_name,
           composition,
           ROW_NUMBER() OVER (ORDER BY composition ASC, interest_name)  AS seq
    FROM   highest_composition
    ORDER  BY composition ASC
    LIMIT 10
)
/* 4. Return the requested columns for both groups                    */
SELECT month_year   AS "MM-YYYY",
       interest_name,
       composition
FROM (
      SELECT * FROM top10
      UNION ALL
      SELECT * FROM bottom10
)
ORDER BY grp, seq;