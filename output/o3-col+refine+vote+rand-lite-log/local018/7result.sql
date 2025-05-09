WITH top_category AS (
    -- 1) Most frequent PCF-violation category in 2021
    SELECT c.pcf_violation_category AS category
    FROM collisions AS c
    JOIN case_ids  AS ci ON ci.case_id = c.case_id
    WHERE ci.db_year = 2021
    GROUP BY c.pcf_violation_category
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_totals AS (
    -- 2) 2011 & 2021 totals and counts for that top category
    SELECT
        ci.db_year,
        COUNT(*)                                           AS total_collisions,
        SUM(
            CASE
                WHEN c.pcf_violation_category = (SELECT category FROM top_category)
                THEN 1 ELSE 0
            END
        )                                                  AS top_category_collisions
    FROM collisions AS c
    JOIN case_ids   AS ci ON ci.case_id = c.case_id
    WHERE ci.db_year IN (2011, 2021)
    GROUP BY ci.db_year
),
shares AS (
    -- 3) Percentage share of the top category in each year
    SELECT
        db_year,
        100.0 * top_category_collisions / total_collisions AS share_pct
    FROM yearly_totals
)
-- 4) Decrease (in percentage points) from 2011 to 2021
SELECT
    ROUND(
        (SELECT share_pct FROM shares WHERE db_year = 2011) -
        (SELECT share_pct FROM shares WHERE db_year = 2021),
        4
    ) AS decrease_in_percentage_points;