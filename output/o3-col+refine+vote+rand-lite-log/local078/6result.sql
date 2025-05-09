WITH max_comp AS (
    -- highest composition reached by every interest category
    SELECT
        im.interest_name,
        MAX(mt.composition) AS max_composition
    FROM interest_metrics  AS mt
    JOIN interest_map      AS im
      ON im.id = mt.interest_id
    GROUP BY im.interest_name
),
ranked AS (
    -- rank the categories from highest → lowest and vice-versa
    SELECT
        interest_name,
        max_composition,
        ROW_NUMBER() OVER (ORDER BY max_composition DESC) AS r_desc,
        ROW_NUMBER() OVER (ORDER BY max_composition ASC)  AS r_asc
    FROM max_comp
),
selected AS (
    -- keep the TOP-10 (largest) and BOTTOM-10 (smallest) peak compositions
    SELECT
        interest_name,
        max_composition
    FROM ranked
    WHERE r_desc <= 10               -- top 10
       OR r_asc  <= 10               -- bottom 10
)
-- return the month-year when each of those peak values occurred
SELECT
    mt.month_year      AS time,      -- MM-YYYY
    im.interest_name,
    mt.composition
FROM interest_metrics AS mt
JOIN interest_map     AS im ON im.id = mt.interest_id
JOIN selected         AS s  ON s.interest_name = im.interest_name
WHERE mt.composition = s.max_composition
ORDER BY mt.composition DESC,        -- show TOP first, then BOTTOM
         im.interest_name,
         mt.month_year;