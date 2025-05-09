WITH psoriasis AS (
    SELECT "id" AS disease_id
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.DISEASES
    WHERE LOWER("name") = 'psoriasis'          -- EFO_0000676
),
assoc AS (
    SELECT a."targetId",
           a."score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT a
    JOIN psoriasis p
      ON a."diseaseId" = p.disease_id
),
mean_calc AS (
    SELECT AVG("score") AS mean_score
    FROM assoc
),
closest AS (
    SELECT a."targetId",
           ABS(a."score" - m.mean_score) AS diff_to_mean
    FROM assoc a
    CROSS JOIN mean_calc m
    ORDER BY diff_to_mean ASC
    LIMIT 1
)
SELECT t."approvedSymbol"
FROM closest c
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
  ON t."id" = c."targetId";