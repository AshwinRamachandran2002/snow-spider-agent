SELECT
    pkg_name AS package_name,
    COUNT(*) AS frequency
FROM (
    SELECT
        REGEXP_REPLACE(
            REGEXP_SUBSTR(TRIM(lines.value), '"([^"]+)"', 1, 1, 'e', 1),
            '"',
            ''
        ) AS pkg_name
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
         LATERAL SPLIT_TO_TABLE(
             TRIM(
                 SPLIT_PART(
                     SUBSTR(
                         sc."content",
                         POSITION('import (' IN sc."content") + 8,
                         10000
                     ),
                     ')',
                     1
                 )
             ),
             '\n'
         ) lines
    WHERE sc."content" ILIKE '%import (%'
      AND lines.value ILIKE '%"%"%'
) extracted
WHERE pkg_name IS NOT NULL
GROUP BY pkg_name
ORDER BY frequency DESC NULLS LAST, package_name
LIMIT 10;