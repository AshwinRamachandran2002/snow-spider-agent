WITH
/* 1) LGG participants represented in the mutation (MC3) table */
lgg_cases AS (
  SELECT DISTINCT "ParticipantBarcode"
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
  WHERE "Study" = 'LGG'
),

/* 2) LGG participants whose TP53 mutation passed all filters */
tp53_mut AS (
  SELECT DISTINCT "ParticipantBarcode"
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
  WHERE "Study"       = 'LGG'
    AND "Hugo_Symbol" = 'TP53'
    AND "FILTER"      = 'PASS'
),

/* 3) Per-participant average log10-transformed DRG2 expression */
expr AS (
  SELECT
      e."ParticipantBarcode",
      AVG( LOG(10 , e."normalized_count" + 1) ) AS g          -- average per participant
  FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
  JOIN lgg_cases c
    ON e."ParticipantBarcode" = c."ParticipantBarcode"
  WHERE e."Study"  = 'LGG'
    AND e."Symbol" = 'DRG2'
  GROUP BY e."ParticipantBarcode"
),

/* 4) Label each participant as TP53-mutated (YES) or not (NO) */
label AS (
  SELECT
      e."ParticipantBarcode",
      e.g,
      CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS grp
  FROM expr e
  LEFT JOIN tp53_mut m
    ON e."ParticipantBarcode" = m."ParticipantBarcode"
),

/* 5) Group-wise counts and sums (N, S, Q) */
stats AS (
  SELECT
      grp,
      COUNT(*)          AS N,
      SUM(g)            AS S,
      SUM(POWER(g,2))   AS Q
  FROM label
  GROUP BY grp
),

/* 6) Assemble statistics and compute Welch’s t-score */
calc AS (
  SELECT
      (SELECT N FROM stats WHERE grp = 'YES')       AS Ny,
      (SELECT N FROM stats WHERE grp = 'NO')        AS Nn,
      (SELECT S / N FROM stats WHERE grp = 'YES')   AS avg_y,
      (SELECT S / N FROM stats WHERE grp = 'NO')    AS avg_n,
      (SELECT S FROM stats WHERE grp = 'YES')       AS Sy,
      (SELECT Q FROM stats WHERE grp = 'YES')       AS Qy,
      (SELECT S FROM stats WHERE grp = 'NO')        AS Sn,
      (SELECT Q FROM stats WHERE grp = 'NO')        AS Qn
)

/* 7) Final output */
SELECT
    Ny,
    Nn,
    avg_y,
    avg_n,
    (avg_y - avg_n) /
    SQRT(
        ((Qy - Sy * Sy / Ny) / (Ny - 1)) / Ny +
        ((Qn - Sn * Sn / Nn) / (Nn - 1)) / Nn
    ) AS "T_score"
FROM calc;