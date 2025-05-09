WITH Stats AS (
   SELECT
      CASE WHEN M."ParticipantBarcode" IS NOT NULL THEN 'Mutated' ELSE 'Non-Mutated' END AS Mutation_Status,
      COUNT(*) AS N,
      AVG(G."normalized_count") AS Mean_Expression,
      VAR_SAMP(G."normalized_count") AS Variance
   FROM
      PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" G
   LEFT JOIN
      (
        SELECT DISTINCT "ParticipantBarcode"
        FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE "Hugo_Symbol" = 'TP53' AND "Study" = 'LGG'
      ) M
   ON G."ParticipantBarcode" = M."ParticipantBarcode"
   WHERE
      G."Study" = 'LGG' AND G."Symbol" = 'DRG2'
   GROUP BY
      CASE WHEN M."ParticipantBarcode" IS NOT NULL THEN 'Mutated' ELSE 'Non-Mutated' END
)
SELECT
   ROUND( (M.Mean_Expression - N.Mean_Expression) / SQRT( (M.Variance / M.N) + (N.Variance / N.N) ), 4) AS "t-score"
FROM
   (SELECT * FROM Stats WHERE Mutation_Status = 'Mutated' AND N >= 10 AND Variance > 0) M,
   (SELECT * FROM Stats WHERE Mutation_Status = 'Non-Mutated' AND N >= 10 AND Variance > 0) N;