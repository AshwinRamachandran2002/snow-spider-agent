WITH cause_counts AS (          -- collisions per cause in each calendar year
    SELECT 
        CAST(substr("collision_date",1,4) AS INTEGER)   AS year,
        "primary_collision_factor"                     AS cause,
        COUNT(*)                                       AS cnt
    FROM   "collisions"
    WHERE  "collision_date" IS NOT NULL
      AND  "primary_collision_factor" IS NOT NULL
    GROUP  BY year, cause
),
ranked AS (                     -- rank causes within each year
    SELECT year,
           cause,
           ROW_NUMBER() OVER (PARTITION BY year
                              ORDER BY cnt DESC, cause) AS rn
    FROM   cause_counts
),
top2 AS (                       -- keep the two most frequent causes
    SELECT year,
           cause,
           rn
    FROM   ranked
    WHERE  rn <= 2
),
ordered_top2 AS (               -- order them so group_concat is consistent
    SELECT year,
           cause,
           rn
    FROM   top2
    ORDER  BY year, rn
),
year_combos AS (                -- concatenate the two causes per year
    SELECT year,
           GROUP_CONCAT(cause, ',') AS combo
    FROM   ordered_top2
    GROUP  BY year
),
diffs AS (                      -- compare with the previous year's combo
    SELECT year,
           combo,
           LAG(combo) OVER (ORDER BY year) AS prev_combo
    FROM   year_combos
)
SELECT year
FROM   diffs
WHERE  prev_combo IS NULL        -- first year in the data set
   OR  combo <> prev_combo       -- combo changes vs. preceding year
ORDER  BY year;