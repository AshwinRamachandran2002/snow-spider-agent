WITH max_comp AS (               -- highest composition per interest category
    SELECT
        interest_id,
        MAX(composition) AS max_comp
    FROM interest_metrics
    GROUP BY interest_id
),
peak_month AS (                  -- month-year in which that peak occurred
    SELECT
        im.interest_id,
        MIN(im.month_year) AS month_year,   -- choose the earliest if a tie
        mc.max_comp           AS composition
    FROM interest_metrics  im
    JOIN max_comp          mc
      ON im.interest_id = mc.interest_id
     AND im.composition  = mc.max_comp
    GROUP BY im.interest_id
),
peak_info AS (                   -- attach the readable interest name
    SELECT
        pm.month_year   AS time,
        mp.interest_name,
        pm.composition
    FROM peak_month      pm
    JOIN interest_map    mp
      ON pm.interest_id = mp.id
),
top10 AS (                       -- ten highest peak compositions
    SELECT *
    FROM   peak_info
    ORDER BY composition DESC, interest_name
    LIMIT 10
),
bottom10 AS (                    -- ten lowest peak compositions
    SELECT *
    FROM   peak_info
    ORDER BY composition ASC, interest_name
    LIMIT 10
)
                     -- final output: top 10 followed by bottom 10
SELECT * FROM top10
UNION ALL
SELECT * FROM bottom10;