SELECT
    CASE
        WHEN REGEXP_LIKE(line.value::STRING, '[ \t]+$') THEN 'trailing'   -- line ends with blank
        WHEN REGEXP_LIKE(line.value::STRING, '^ ')      THEN 'Space'      -- line starts with space
        ELSE 'Other'                                                    -- all other lines
    END AS line_type,
    COUNT(*) AS total_count
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
     LATERAL SPLIT_TO_TABLE(c."content", '\n') AS line
WHERE c."content" IS NOT NULL
GROUP BY line_type
ORDER BY total_count DESC NULLS LAST, line_type;