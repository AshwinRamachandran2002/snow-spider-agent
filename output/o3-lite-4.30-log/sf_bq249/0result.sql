WITH lines AS (
    SELECT
        CASE
            WHEN f.value::STRING RLIKE '\\s+$' THEN 'trailing'      -- ends with blank
            WHEN f.value::STRING RLIKE '^ +'   THEN 'Space'         -- starts with space
            ELSE 'Other'                                            -- everything else
        END AS "line_type"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN( INPUT => SPLIT(c."content", '\n') ) f
)
SELECT
    "line_type",
    COUNT(*) AS "total_count"
FROM lines
GROUP BY "line_type"
ORDER BY "line_type";