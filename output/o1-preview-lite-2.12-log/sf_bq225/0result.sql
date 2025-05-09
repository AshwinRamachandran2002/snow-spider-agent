WITH extension_language_map("extension", "language") AS (
    SELECT * FROM VALUES
        ('asm', 'Assembly'),
        ('nasm', 'Assembly'),
        ('c', 'C'),
        ('h', 'C'),
        ('cs', 'C#'),
        ('c++', 'C++'),
        ('cpp', 'C++'),
        ('h++', 'C++'),
        ('hpp', 'C++'),
        ('css', 'CSS'),
        ('clj', 'Clojure'),
        ('lisp', 'Common Lisp'),
        ('d', 'D'),
        ('dart', 'Dart'),
        ('dockerfile', 'Dockerfile'),
        ('ex', 'Elixir'),
        ('exs', 'Elixir'),
        ('erl', 'Erlang'),
        ('go', 'Go'),
        ('groovy', 'Groovy'),
        ('html', 'HTML'),
        ('htm', 'HTML'),
        ('hs', 'Haskell'),
        ('hx', 'Haxe'),
        ('json', 'JSON'),
        ('java', 'Java'),
        ('js', 'JavaScript'),
        ('cjs', 'JavaScript'),
        ('jl', 'Julia'),
        ('kt', 'Kotlin'),
        ('ktm', 'Kotlin'),
        ('kts', 'Kotlin'),
        ('lua', 'Lua'),
        ('matlab', 'MATLAB'),
        ('m', 'MATLAB'),
        ('md', 'Markdown'),
        ('markdown', 'Markdown'),
        ('mdown', 'Markdown'),
        ('php', 'PHP'),
        ('ps1', 'PowerShell'),
        ('psd1', 'PowerShell'),
        ('psm1', 'PowerShell'),
        ('py', 'Python'),
        ('r', 'R'),
        ('rb', 'Ruby'),
        ('rs', 'Rust'),
        ('scss', 'SCSS'),
        ('sql', 'SQL'),
        ('sass', 'Sass'),
        ('scala', 'Scala'),
        ('sh', 'Shell'),
        ('bash', 'Shell'),
        ('swift', 'Swift'),
        ('ts', 'TypeScript'),
        ('vue', 'Vue'),
        ('xml', 'XML'),
        ('yml', 'YAML'),
        ('yaml', 'YAML')
)

SELECT
    el."language",
    COUNT(*) AS "file_count"
FROM (
    SELECT
        f."id",
        f."path",
        LOWER(REGEXP_REPLACE(f."path", '^.*/', '')) AS "file_name",
        CASE
            WHEN LOWER(REGEXP_REPLACE(f."path", '^.*/', '')) = 'dockerfile' THEN 'dockerfile'
            WHEN POSITION('.' IN REGEXP_REPLACE(f."path", '^.*/', '')) > 0 THEN LOWER(SPLIT_PART(REGEXP_REPLACE(f."path", '^.*/', ''), '.', -1))
            ELSE NULL
        END AS "extension"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
        ON f."id" = c."id"
    WHERE c."content" IS NOT NULL AND c."content" != ''
        AND (c."binary" = FALSE OR c."binary" IS NULL)
) AS files_with_extensions
JOIN extension_language_map el
    ON files_with_extensions."extension" = el."extension"
GROUP BY el."language"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 10;