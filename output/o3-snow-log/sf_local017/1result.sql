WITH category_counts AS (   /* how often each PCF category appears per year */
    SELECT 
        ci."db_year",
        c."pcf_violation_category",
        COUNT(*) AS "cnt"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"   c
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."CASE_IDS"    ci
          ON c."case_id" = ci."case_id"
    WHERE c."pcf_violation_category" IS NOT NULL
    GROUP BY ci."db_year", c."pcf_violation_category"
),
ranked AS (                    /* keep the two most-frequent categories each year */
    SELECT
        "db_year",
        "pcf_violation_category",
        "cnt",
        ROW_NUMBER() OVER (PARTITION BY "db_year"
                           ORDER BY "cnt" DESC NULLS LAST, "pcf_violation_category") AS rnk
    FROM category_counts
),
per_year_top2 AS (             /* store the top-2 set (alphabetically) per year */
    SELECT
        "db_year",
        LISTAGG("pcf_violation_category", ',')
            WITHIN GROUP (ORDER BY "pcf_violation_category")           AS top2_categories
    FROM ranked
    WHERE rnk <= 2
    GROUP BY "db_year"
),
common_pair AS (               /* the pair that occurs in the greatest # of years */
    SELECT top2_categories
    FROM   per_year_top2
    GROUP  BY top2_categories
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
SELECT p."db_year"
FROM   per_year_top2  p
JOIN   common_pair    c
       ON 1 = 1
WHERE  p.top2_categories <> c.top2_categories
ORDER  BY p."db_year";