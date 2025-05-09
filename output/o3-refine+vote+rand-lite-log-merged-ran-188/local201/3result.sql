WITH signatures AS (
  SELECT
    words,
    -- build a “signature” = alphabetically-sorted letters of the word
    (SELECT GROUP_CONCAT(ch, '')
       FROM (
              SELECT SUBSTR(words, 1, 1) AS ch
              UNION ALL SELECT SUBSTR(words, 2, 1)
              UNION ALL SELECT SUBSTR(words, 3, 1)
              UNION ALL SELECT SUBSTR(words, 4, 1)
              UNION ALL SELECT CASE WHEN LENGTH(words) = 5
                                    THEN SUBSTR(words, 5, 1) END
            )
      WHERE ch IS NOT NULL
      ORDER BY ch
    ) AS signature
  FROM word_list
  WHERE LENGTH(words) IN (4, 5)
)
SELECT
  s1.words             AS word,
  (SELECT COUNT(*)
     FROM signatures s2
     WHERE s2.signature = s1.signature)  AS anagram_count
FROM signatures s1
WHERE s1.words LIKE 'r%'                      -- starts with 'r'
  AND (SELECT COUNT(*)
         FROM signatures s3
         WHERE s3.signature = s1.signature) > 1   -- has ≥1 anagram
GROUP BY s1.words
ORDER BY s1.words
LIMIT 10;