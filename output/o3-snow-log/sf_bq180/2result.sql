SELECT
    "module_name",
    COUNT(*) AS "total_occurrences"
FROM (
        /* -------- Python: capture module after 'import' or 'from' ---------- */
        SELECT
            REGEXP_SUBSTR(
                ln.value::STRING,
                '([Ff]rom|[Ii]mport)[[:space:]]+([A-Za-z0-9_]+)',
                1, 1, 'i', 2      -- return 2nd capture-group = module name
            ) AS "module_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
             LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) ln
        WHERE LOWER(sc."sample_path") LIKE '%.py'
          AND ln.value::STRING ILIKE '%import%'

        UNION ALL

        /* ---------------------- R: capture library() calls ------------------ */
        SELECT
            REGEXP_SUBSTR(
                ln.value::STRING,
                'library[[:space:]]*\\([[:space:]]*([A-Za-z0-9_.]+)',
                1, 1, 'i', 1      -- return 1st capture-group = package name
            ) AS "module_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
             LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) ln
        WHERE LOWER(sc."sample_path") LIKE '%.r'
          AND ln.value::STRING ILIKE '%library(%'
) AS all_modules
WHERE "module_name" IS NOT NULL
GROUP BY "module_name"
ORDER BY "total_occurrences" DESC NULLS LAST
LIMIT 5;