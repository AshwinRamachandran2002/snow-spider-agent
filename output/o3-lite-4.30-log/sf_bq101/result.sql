WITH imports AS (
    SELECT
        REGEXP_REPLACE(
            REGEXP_SUBSTR(
                f.value,
                'import\\s+(static\\s+)?([A-Za-z0-9_\\.]+)',
                1, 1, 'e', 2
            ),
            '\\.[^\\.]+$',
            ''
        ) AS package_name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') f
    WHERE c."sample_path" ILIKE '%.java'
      AND f.value ILIKE 'import %'
      AND REGEXP_SUBSTR(
              f.value,
              'import\\s+(static\\s+)?([A-Za-z0-9_\\.]+)',
              1, 1, 'e', 2
          ) IS NOT NULL
)
SELECT
    package_name,
    COUNT(*) AS total_imports
FROM imports
GROUP BY package_name
ORDER BY total_imports DESC NULLS LAST, package_name
LIMIT 10;