/*-----------------------------------------------------------
  Breast-cancer (TCGA-BRCA) copy-number status per cytoband
  – Release-23 allelic CNV segments (hg38)
  – overlap-weighted, rounded copy number → CNV class
  – % of all BRCA cases falling in each class
-----------------------------------------------------------*/
WITH total_cases AS (   -- number of unique BRCA cases in this release
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/* 1.  Per-case, per-cytoband overlap-weighted (rounded) copy number */
per_case_band AS (
    SELECT
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        s."case_barcode",
        ROUND(         /* weighted average copy number, then rounded   */
            SUM( (LEAST(b."hg38_stop", s."end_pos")
                  - GREATEST(b."hg38_start", s."start_pos")) * s."copy_number" )
            / NULLIF(
                SUM( LEAST(b."hg38_stop", s."end_pos")
                    - GREATEST(b."hg38_start", s."start_pos")), 0)
        )                                               AS round_cn
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"            b
      ON b."chromosome" = s."chromosome"
    WHERE s."project_short_name" = 'TCGA-BRCA'
      AND GREATEST(b."hg38_start", s."start_pos")       /* ensure bp overlap  */
          < LEAST(b."hg38_stop",  s."end_pos")
    GROUP BY b."cytoband_name", b."hg38_start", b."hg38_stop", s."case_barcode"
),

/* 2.  Translate rounded copy number → CNV class */
classified AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CASE  WHEN round_cn = 0 THEN 'HomDel'
              WHEN round_cn = 1 THEN 'HetDel'
              WHEN round_cn = 2 THEN 'Diploid'
              WHEN round_cn = 3 THEN 'Gain'
              ELSE 'Amplif'
        END                                           AS cnv_class
    FROM per_case_band
),

/* 3.  Count cases of each class per cytoband */
band_counts AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        cnv_class,
        COUNT(*)                                      AS n_case
    FROM classified
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop", cnv_class
)

/* 4.  Convert raw counts to % of all BRCA cases (wide format) */
SELECT
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",
    ROUND(100.0 * SUM(CASE WHEN c.cnv_class = 'HomDel'  THEN n_case ELSE 0 END) / t.n_cases, 2) AS "percent_homdel",
    ROUND(100.0 * SUM(CASE WHEN c.cnv_class = 'HetDel'  THEN n_case ELSE 0 END) / t.n_cases, 2) AS "percent_hetdel",
    ROUND(100.0 * SUM(CASE WHEN c.cnv_class = 'Diploid' THEN n_case ELSE 0 END) / t.n_cases, 2) AS "percent_diploid",
    ROUND(100.0 * SUM(CASE WHEN c.cnv_class = 'Gain'    THEN n_case ELSE 0 END) / t.n_cases, 2) AS "percent_gain",
    ROUND(100.0 * SUM(CASE WHEN c.cnv_class = 'Amplif'  THEN n_case ELSE 0 END) / t.n_cases, 2) AS "percent_amplif"
FROM band_counts            c
CROSS JOIN total_cases      t
GROUP BY c."cytoband_name", c."hg38_start", c."hg38_stop", t.n_cases
ORDER BY c."cytoband_name";