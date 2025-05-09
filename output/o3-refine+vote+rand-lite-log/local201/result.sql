WITH filtered AS (      -- 4‑5 letters, start with lowercase ‘r’
    SELECT DISTINCT words AS word
    FROM word_list
    WHERE length(words) BETWEEN 4 AND 5
      AND word GLOB 'r*'                                -- case–sensitive
),
/* split every word into its characters */
chars(word, pos, len, ch) AS (
    SELECT word, 1, length(word), substr(word,1,1)
    FROM filtered
    UNION ALL
    SELECT word, pos+1, len, substr(word,pos+1,1)
    FROM chars
    WHERE pos < len
),
/* build a “signature”: the letters of the word sorted alphabetically */
sigs AS (
    SELECT word,
           group_concat(ch,'') AS signature
    FROM (
        SELECT word, ch
        FROM chars
        ORDER BY word, ch                 -- sort letters inside each word
    )
    GROUP BY word
),
/* count other words (same length) that share the signature */
anagrams AS (
    SELECT s1.word,
           ( SELECT COUNT(*) 
             FROM sigs s2 
             WHERE s2.signature = s1.signature
               AND s2.word <> s1.word ) AS anagram_count
    FROM sigs s1
)
SELECT word, anagram_count
FROM anagrams
WHERE anagram_count > 0          -- at least one anagram
ORDER BY word
LIMIT 10;