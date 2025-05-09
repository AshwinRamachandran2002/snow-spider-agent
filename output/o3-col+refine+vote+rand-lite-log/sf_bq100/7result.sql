SELECT
    package,
    COUNT(*) AS times_used
FROM (
    SELECT
        RTRIM(LTRIM(REGEXP_SUBSTR(f.VALUE::STRING,
                                  '"([^"]+)"',          -- text inside quotes
                                  1, 1, 'e', 1), '"'),  -- strip leading quote
              '"')                                       -- strip trailing quote
        AS package
    FROM (
        /* grab the complete multi-line import block */
        SELECT
            REGEXP_SUBSTR("content",
                          'import[[:space:]]*\\(([^)]*)\\)',
                          1, 1, 'e', 1) AS import_block
        FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
        WHERE "content" ILIKE '%import (%'
    ) s,
    /* split import block into individual lines */
    LATERAL FLATTEN(INPUT => SPLIT(s.import_block, '\n')) f
) 
WHERE package IS NOT NULL
GROUP BY package
ORDER BY times_used DESC NULLS LAST
LIMIT 10;