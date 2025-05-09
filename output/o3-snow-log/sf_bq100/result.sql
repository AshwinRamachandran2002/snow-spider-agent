WITH import_blocks AS (
    /* 1. Pull every multi-line `import ( … )` block */
    SELECT REGEXP_SUBSTR("content",
                         'import[ ]*\\([\\s\\S]*?\\)',
                         1, 1, 'e')    AS "import_block"
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE  "content" ILIKE '%import (%'
), split_lines AS (
    /* 2. Split each block into individual lines */
    SELECT TRIM(f.value::STRING) AS "line"
    FROM   import_blocks,
           LATERAL FLATTEN( input => SPLIT("import_block", '\n') ) f
), extracted_pkgs AS (
    /* 3. Extract the first double-quoted package path on each line */
    SELECT REGEXP_SUBSTR("line",
                         '\"([^\"]+)\"',
                         1, 1, 'e', 1) AS "package"
    FROM   split_lines
)
SELECT  "package",
        COUNT(*) AS "frequency"
FROM    extracted_pkgs
WHERE   "package" IS NOT NULL
GROUP BY "package"
ORDER BY "frequency" DESC NULLS LAST
LIMIT   10;