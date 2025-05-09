WITH per_interest AS (          -- highest composition per interest
    SELECT CAST(interest_id AS INTEGER)        AS interest_id,
           MAX(composition)                    AS max_comp
    FROM   interest_metrics
    GROUP  BY CAST(interest_id AS INTEGER)
),
best_month AS (                 -- month(s) where that max occurred
    SELECT CAST(im.interest_id AS INTEGER)     AS interest_id,
           im.month_year,
           im.composition,
           ROW_NUMBER() OVER (PARTITION BY CAST(im.interest_id AS INTEGER)
                               ORDER BY im.composition DESC, im.month_year) AS rn
    FROM   interest_metrics  im
    JOIN   per_interest      p
           ON CAST(im.interest_id AS INTEGER) = p.interest_id
          AND im.composition = p.max_comp
),
best_unique AS (                -- keep just one month per interest
    SELECT interest_id,
           month_year,
           composition
    FROM   best_month
    WHERE  rn = 1
),
with_names AS (                 -- attach interest names
    SELECT bu.month_year,
           imap.interest_name,
           bu.composition
    FROM   best_unique bu
    JOIN   interest_map imap
           ON bu.interest_id = imap.id
),
top10 AS (                      -- ten highest‑scoring interests
    SELECT month_year,
           interest_name,
           composition,
           1 AS grp,
           ROW_NUMBER() OVER (ORDER BY composition DESC, interest_name) AS rn
    FROM   with_names
    ORDER  BY composition DESC, interest_name
    LIMIT  10
),
bottom10 AS (                   -- ten lowest‑scoring interests
    SELECT month_year,
           interest_name,
           composition,
           2 AS grp,
           ROW_NUMBER() OVER (ORDER BY composition ASC, interest_name) AS rn
    FROM   with_names
    ORDER  BY composition ASC, interest_name
    LIMIT  10
)
SELECT month_year      AS "Time(MM-YYYY)",
       interest_name   AS "Interest Name",
       ROUND(composition,2) AS "Composition"
FROM  (
       SELECT * FROM top10
       UNION ALL
       SELECT * FROM bottom10
      )
ORDER BY grp, rn;