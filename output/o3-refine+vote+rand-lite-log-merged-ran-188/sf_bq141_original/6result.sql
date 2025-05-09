/*---------------------------------------------------------------
  Predict clinical stage for TCGA‑KIRP cases from MT‑CO gene
  expression (Snowflake SQL)

  • Stage = COALESCE(clinical_stage , pathologic_stage)
  • Split patients deterministically with HASH( case_barcode )
----------------------------------------------------------------*/

WITH kirp_cases AS (      /* 1.  TCGA‑KIRP cases that have a stage */
    SELECT DISTINCT
           c."case_barcode",
           COALESCE(c."clinical_stage", c."pathologic_stage") AS "stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1" c
    WHERE c."disease_code" = 'KIRP'
      AND COALESCE(c."clinical_stage", c."pathologic_stage") IS NOT NULL
),

expr_raw AS (             /* 2.  MT‑CO gene expression (FPKM‑UQ)   */
    SELECT
        r."case_barcode",
        r."gene_name",
        AVG(r."HTSeq__FPKM_UQ") AS "fpkm_uq"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION" r
    WHERE r."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP BY r."case_barcode", r."gene_name"
),

expr_pivot AS (           /* 3.  pivot to one row per case          */
    SELECT
        "case_barcode",
        MAX(CASE WHEN "gene_name"='MT-CO1' THEN "fpkm_uq" END) AS "mt_co1",
        MAX(CASE WHEN "gene_name"='MT-CO2' THEN "fpkm_uq" END) AS "mt_co2",
        MAX(CASE WHEN "gene_name"='MT-CO3' THEN "fpkm_uq" END) AS "mt_co3"
    FROM expr_raw
    GROUP BY "case_barcode"
),

data AS (                 /* 4.  merge + create split key (0‑8 train, 9 test) */
    SELECT
        k."case_barcode",
        k."stage",
        COALESCE(p."mt_co1",0) AS "mt_co1",
        COALESCE(p."mt_co2",0) AS "mt_co2",
        COALESCE(p."mt_co3",0) AS "mt_co3",
        MOD(ABS(HASH(k."case_barcode")),10) AS "split_key"
    FROM kirp_cases k
    JOIN expr_pivot p
      ON k."case_barcode" = p."case_barcode"
),

training AS (             /* 5.  90 % training */
    SELECT * FROM data WHERE "split_key" < 9
),

stage_centroid AS (       /* 6.  stage‑specific mean expression     */
    SELECT
        "stage",
        AVG("mt_co1") AS "avg_co1",
        AVG("mt_co2") AS "avg_co2",
        AVG("mt_co3") AS "avg_co3"
    FROM training
    GROUP BY "stage"
),

test AS (                 /* 7.  10 % test set                      */
    SELECT * FROM data WHERE "split_key" = 9
),

dist AS (                 /* 8.  Euclidean distance to centroids    */
    SELECT
        t."case_barcode",
        s."stage"                                             AS "stage_candidate",
        SQRT( POWER(t."mt_co1"-s."avg_co1",2) +
              POWER(t."mt_co2"-s."avg_co2",2) +
              POWER(t."mt_co3"-s."avg_co3",2) )               AS "dist"
    FROM test t
    CROSS JOIN stage_centroid s
),

nearest AS (              /* 9.  choose nearest stage per patient   */
    SELECT
        d."case_barcode",
        d."stage_candidate",
        ROW_NUMBER() OVER (PARTITION BY d."case_barcode"
                           ORDER BY d."dist") AS rn
    FROM dist d
    QUALIFY rn = 1
)

SELECT
    "case_barcode",
    "stage_candidate" AS "predicted_clinical_stage"
FROM nearest
ORDER BY "case_barcode";