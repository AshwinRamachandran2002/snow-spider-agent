WITH ranked AS (
    SELECT
        ci."db_year",
        co."pcf_violation_category",
        COUNT(*)                                     AS cnt,
        RANK() OVER (PARTITION BY ci."db_year"
                     ORDER BY COUNT(*) DESC)         AS rk
    FROM   "collisions" AS co
    JOIN   "case_ids"  AS ci USING ("case_id")
    WHERE  co."pcf_violation_category" IS NOT NULL
    GROUP  BY ci."db_year", co."pcf_violation_category"
),
top2 AS (                     -- keep only the two most common causes per year
    SELECT  "db_year", "pcf_violation_category", rk
    FROM    ranked
    WHERE   rk <= 2
),
year_pairs AS (               -- build a canonical “cause-pair” string per year
    SELECT
        "db_year",
        MAX(CASE WHEN rk = 1 THEN "pcf_violation_category" END) || ' | ' ||
        MAX(CASE WHEN rk = 2 THEN "pcf_violation_category" END) AS top2_pair
    FROM   top2
    GROUP  BY "db_year"
),
modal_pair AS (               -- the pair that occurs in the greatest # of years
    SELECT  top2_pair
    FROM    year_pairs
    GROUP   BY top2_pair
    ORDER   BY COUNT(*) DESC
    LIMIT   1
)
SELECT  yp."db_year"          -- year(s) whose Top-2 causes differ from “modal” pair
FROM    year_pairs AS yp
WHERE   yp.top2_pair NOT IN (SELECT top2_pair FROM modal_pair)
ORDER   BY yp."db_year";