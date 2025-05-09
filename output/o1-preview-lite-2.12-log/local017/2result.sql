WITH year_causes AS (
    SELECT substr("collision_date", 1, 4) AS "year", "pcf_violation_category", COUNT(*) AS "accident_count"
    FROM "collisions"
    WHERE "pcf_violation_category" != ''
    GROUP BY "year", "pcf_violation_category"
),
year_top_causes AS (
    SELECT "year", "pcf_violation_category"
    FROM (
        SELECT year_causes.*, ROW_NUMBER() OVER (PARTITION BY "year" ORDER BY "accident_count" DESC) AS rn
        FROM year_causes
    ) WHERE rn <= 2
),
year_top_causes_list AS (
    SELECT "year", GROUP_CONCAT("pcf_violation_category", ',') AS "top_causes"
    FROM year_top_causes
    GROUP BY "year"
),
top_causes_counts AS (
    SELECT "top_causes", COUNT(*) AS "year_count"
    FROM year_top_causes_list
    GROUP BY "top_causes"
),
unique_top_causes AS (
    SELECT "top_causes"
    FROM top_causes_counts
    WHERE "year_count" = 1
)
SELECT "year"
FROM year_top_causes_list
WHERE "top_causes" IN (SELECT "top_causes" FROM unique_top_causes);