WITH lines AS (
    SELECT
        CASE
            WHEN REGEXP_LIKE(f.value::STRING, ' $')               THEN 'trailing'
            WHEN REGEXP_LIKE(f.value::STRING, '^ ')               THEN 'Space'
            ELSE                                                       'Other'
        END                                                      AS category
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  sc,
         LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n'))  f
)
SELECT
    category,
    COUNT(*) AS total_occurrences
FROM lines
GROUP BY category
ORDER BY total_occurrences DESC, category;