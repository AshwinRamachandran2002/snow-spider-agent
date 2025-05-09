WITH lines AS (
    SELECT
        f.value::string AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) f
),
classified AS (
    SELECT
        CASE
            WHEN REGEXP_LIKE(line, ' +$')       THEN 'trailing'   -- ends with space(s)
            WHEN REGEXP_LIKE(line, '^ +')       THEN 'Space'      -- starts with space(s)
            ELSE                                   'Other'        -- all other lines
        END AS category
    FROM lines
)
SELECT
    category,
    COUNT(*) AS occurrences
FROM classified
GROUP BY category
ORDER BY category;