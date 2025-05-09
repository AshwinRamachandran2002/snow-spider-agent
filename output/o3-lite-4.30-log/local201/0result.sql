WITH RECURSIVE
-- keep only 4‑ to 5‑letter words starting with lowercase “r”
filtered AS (
    SELECT words AS word
    FROM word_list
    WHERE words LIKE 'r%'                      -- starts with r
      AND length(words) BETWEEN 4 AND 5
),
-- split every word into its individual characters
split(word, pos, ch) AS (
    SELECT word,
           1,
           substr(word, 1, 1)
    FROM filtered
    UNION ALL
    SELECT word,
           pos + 1,
           substr(word, pos + 1, 1)
    FROM split
    WHERE pos + 1 <= length(word)
),
-- canonical signature = its letters sorted (case‑sensitive)
canon AS (
    SELECT word,
           length(word)               AS len,
           group_concat(ch, '')       AS canon
    FROM (
        SELECT word,
               ch
        FROM split
        ORDER BY word, ch             -- sort letters a‑z for each word
    )
    GROUP BY word
),
-- anagram family sizes (same length, same canonical signature)
families AS (
    SELECT canon,
           len,
           COUNT(*) AS anagram_count
    FROM canon
    GROUP BY canon, len
    HAVING anagram_count > 1          -- only families with ≥ 2 members
)
SELECT canon.word      AS word,
       families.anagram_count
FROM canon
JOIN families
  ON canon.canon = families.canon
 AND canon.len   = families.len
ORDER BY canon.word
LIMIT 10;