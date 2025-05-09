SELECT
    CASE
        WHEN REGEXP_LIKE(line, '\\s$') THEN 'trailing'   -- ends with whitespace
        WHEN REGEXP_LIKE(line, '^ ')   THEN 'Space'      -- starts with space
        ELSE 'Other'                                   -- everything else
    END                           AS "line_type",
    COUNT(*)                      AS "total_occurrences"
FROM (
    SELECT
        f.value::STRING AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
) AS lines
GROUP BY 1
ORDER BY "total_occurrences" DESC NULLS LAST;