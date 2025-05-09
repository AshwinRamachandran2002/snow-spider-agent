SELECT
    category,
    COUNT(*) AS occurrences
FROM (
    SELECT
        CASE
            WHEN REGEXP_LIKE(line,'[ \t]+$') THEN 'trailing'     -- ends with blank character
            WHEN REGEXP_LIKE(line,'^ ')        THEN 'Space'        -- starts with a space
            ELSE                                   'Other'         -- all remaining lines
        END AS category
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
          ,LATERAL FLATTEN( INPUT => SPLIT("content", '\n') ) f   -- split file into lines
          ,LATERAL ( SELECT f.value::string AS line )
) AS categorized
GROUP BY category
ORDER BY category;