WITH max_comp AS (                -- highest composition per category
    SELECT
        interest_id,
        MAX(composition) AS max_comp
    FROM interest_metrics
    GROUP BY interest_id
),
best_rows AS (                     -- rows where that peak occurs
    SELECT
        im.interest_id,
        im.month_year,
        im.composition
    FROM interest_metrics AS im
    JOIN max_comp AS mc
      ON im.interest_id = mc.interest_id
     AND im.composition = mc.max_comp
),
joined AS (                        -- add readable name & round to 4 dp
    SELECT
        br.month_year                AS time,
        mp.interest_name,
        ROUND(br.composition,4)      AS composition_value
    FROM best_rows AS br
    JOIN interest_map AS mp
      ON mp.id = br.interest_id
),
top10 AS (                         -- 10 largest peaks
    SELECT *
    FROM joined
    ORDER BY composition_value DESC, interest_name
    LIMIT 10
),
bottom10 AS (                      -- 10 smallest peaks
    SELECT *
    FROM joined
    ORDER BY composition_value ASC, interest_name
    LIMIT 10
)
SELECT time,
       interest_name,
       composition_value
FROM top10
UNION ALL
SELECT time,
       interest_name,
       composition_value
FROM bottom10;