WITH ext_map AS (
    SELECT column1 AS ext,
           column2 AS language
    FROM VALUES
        ('asm','Assembly'), ('nasm','Assembly'),
        ('c','C'), ('h','C'),
        ('cs','C#'),
        ('c++','C++'), ('cpp','C++'), ('h++','C++'), ('hpp','C++'),
        ('css','CSS'),
        ('clj','Clojure'),
        ('lisp','Common Lisp'),
        ('d','D'),
        ('dart','Dart'),
        ('dockerfile','Dockerfile'),
        ('ex','Elixir'), ('exs','Elixir'),
        ('erl','Erlang'),
        ('go','Go'),
        ('groovy','Groovy'),
        ('html','HTML'), ('htm','HTML'),
        ('hs','Haskell'),
        ('hx','Haxe'),
        ('json','JSON'),
        ('java','Java'),
        ('js','JavaScript'), ('cjs','JavaScript'),
        ('jl','Julia'),
        ('kt','Kotlin'), ('ktm','Kotlin'), ('kts','Kotlin'),
        ('lua','Lua'),
        ('m','MATLAB'), ('matlab','MATLAB'),
        ('md','Markdown'), ('markdown','Markdown'), ('mdown','Markdown'),
        ('php','PHP'),
        ('ps1','PowerShell'), ('psd1','PowerShell'), ('psm1','PowerShell'),
        ('py','Python'),
        ('r','R'),
        ('rb','Ruby'),
        ('rs','Rust'),
        ('scss','SCSS'),
        ('sql','SQL'),
        ('sass','Sass'),
        ('scala','Scala'),
        ('sh','Shell'), ('bash','Shell'),
        ('swift','Swift'),
        ('ts','TypeScript'),
        ('vue','Vue'),
        ('xml','XML'),
        ('yml','YAML'), ('yaml','YAML')
)
SELECT
    language,
    COUNT(*) AS file_count
FROM (
    SELECT
        COALESCE(m.language, 'Other') AS language
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    sf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
      ON sc."id" = sf."id"
    LEFT JOIN ext_map m
      ON LOWER(REGEXP_REPLACE(sf."path", '.*\\.([^./]+)$', '\\1')) = m.ext
    WHERE sc."content" IS NOT NULL
)
WHERE language <> 'Other'
GROUP BY language
ORDER BY file_count DESC NULLS LAST
LIMIT 10;