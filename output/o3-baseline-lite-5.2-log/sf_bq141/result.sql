/*─────────────────────────────────────────────────────────────────────────────
   1.  Pick KIRP cases that have a non‑null clinical_stage
   2.  Gather the three MT‑CO* gene expression values (FPKM‑UQ) per case
   3.  Randomly split cases 90 % / 10 % with HASH‐based buckets
   4.  On the training split, compute stage‑specific mean expression
   5.  For every test‑case, find the nearest stage centroid (Euclidean)
   6.  Return case_barcode + predicted clinical stage
─────────────────────────────────────────────────────────────────────────────*/
WITH kirp_patients AS (   -- step 1
    SELECT DISTINCT
           "case_barcode",
           "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE  "disease_code" = 'KIRP'
      AND  "clinical_stage" IS NOT NULL
),
expr AS (                   -- step 2a
    SELECT
           "case_barcode",
           "gene_name",
           AVG("HTSeq__FPKM_UQ") AS expr_val
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE  "gene_name" IN ('MT-CO3','MT-CO1','MT-CO2')
    GROUP  BY "case_barcode","gene_name"
),
expr_pivot AS (             -- step 2b
    SELECT
           "case_barcode",
           MAX(CASE WHEN "gene_name"='MT-CO1' THEN expr_val END) AS mt_co1,
           MAX(CASE WHEN "gene_name"='MT-CO2' THEN expr_val END) AS mt_co2,
           MAX(CASE WHEN "gene_name"='MT-CO3' THEN expr_val END) AS mt_co3
    FROM   expr
    GROUP  BY "case_barcode"
),
kirp_data AS (              -- combine clinical + expression
    SELECT
           k."case_barcode",
           k."clinical_stage",
           p.mt_co1, p.mt_co2, p.mt_co3
    FROM   kirp_patients k
    JOIN   expr_pivot   p ON k."case_barcode" = p."case_barcode"
),
split AS (                  -- step 3 : random buckets 0‑99
    SELECT *,
           ABS(HASH("case_barcode")) % 100 AS rnd_bucket
    FROM   kirp_data
),
stage_avg AS (              -- step 4 : centroids from training (0‑89)
    SELECT
           "clinical_stage",
           AVG(mt_co1) AS avg_co1,
           AVG(mt_co2) AS avg_co2,
           AVG(mt_co3) AS avg_co3
    FROM   split
    WHERE  rnd_bucket < 90
    GROUP  BY "clinical_stage"
),
distances AS (              -- step 5 : distance of each test case to every centroid
    SELECT
           t."case_barcode",
           s."clinical_stage"          AS stage_candidate,
           SQRT(  POWER(t.mt_co1 - s.avg_co1,2)
                + POWER(t.mt_co2 - s.avg_co2,2)
                + POWER(t.mt_co3 - s.avg_co3,2) )           AS distance,
           ROW_NUMBER() OVER (PARTITION BY t."case_barcode"
                              ORDER BY
                              SQRT(  POWER(t.mt_co1 - s.avg_co1,2)
                                   + POWER(t.mt_co2 - s.avg_co2,2)
                                   + POWER(t.mt_co3 - s.avg_co3,2) ) )  AS rn
    FROM   split      t
    CROSS  JOIN stage_avg  s
    WHERE  t.rnd_bucket >= 90          -- test split
)
--──────────────────────────  step 6 : final prediction  ──────────────────────
SELECT
       "case_barcode",
       stage_candidate AS predicted_clinical_stage
FROM   distances
WHERE  rn = 1
ORDER  BY "case_barcode";