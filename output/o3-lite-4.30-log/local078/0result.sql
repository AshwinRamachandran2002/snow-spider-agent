WITH per_interest_max AS (                 -- peak composition for every interest
    SELECT
        interest_id,
        MAX(composition) AS max_comp
    FROM interest_metrics
    GROUP BY interest_id
),
top10 AS (                                 -- 10 largest peaks
    SELECT
        pim.interest_id,
        im.interest_name,
        pim.max_comp
    FROM per_interest_max pim
    JOIN interest_map im
      ON pim.interest_id = im.id
    ORDER BY pim.max_comp DESC, pim.interest_id
    LIMIT 10
),
bottom10 AS (                              -- 10 smallest peaks
    SELECT
        pim.interest_id,
        im.interest_name,
        pim.max_comp
    FROM per_interest_max pim
    JOIN interest_map im
      ON pim.interest_id = im.id
    ORDER BY pim.max_comp ASC, pim.interest_id
    LIMIT 10
),
extremes AS (                              -- combine top and bottom lists
    SELECT * FROM top10
    UNION
    SELECT * FROM bottom10
),
peak_time AS (                             -- month‑year when each peak occurred
    SELECT
        em.interest_id,
        MIN(em.month_year) AS time         -- earliest month if duplicated
    FROM interest_metrics em
    JOIN extremes ex
      ON em.interest_id = ex.interest_id
     AND em.composition = ex.max_comp
    GROUP BY em.interest_id
)
SELECT
    pt.time                AS time,
    ex.interest_name       AS interest_name,
    ROUND(ex.max_comp,4)   AS composition_value
FROM extremes ex
JOIN peak_time pt
  ON pt.interest_id = ex.interest_id
ORDER BY ex.max_comp DESC;                 -- top 10 first, then bottom 10