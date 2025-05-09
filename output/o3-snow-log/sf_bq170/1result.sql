/*---------------------------------------------------------------------------
  Copy-number–variation (CNV) frequencies for every cytoband in TCGA-BRCA
  (GDC Release 23 ‑ allelic segments)
---------------------------------------------------------------------------*/
WITH brca_segments AS (          -- TCGA-BRCA segments
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
total_cases AS (                 -- # of distinct BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS total_cases
    FROM brca_segments
),
band_case_weighted AS (          -- overlap-weighted CN per case × cytoband
    SELECT
        c."chromosome",
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        s."case_barcode",
        SUM( (LEAST(s."end_pos",  c."hg38_stop")
            - GREATEST(s."start_pos", c."hg38_start") + 1)
            * s."copy_number")                              AS weighted_sum,
        SUM(  LEAST(s."end_pos",  c."hg38_stop")
            - GREATEST(s."start_pos", c."hg38_start") + 1)  AS overlap_total
    FROM brca_segments                    s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" c
      ON s."chromosome" = c."chromosome"
    WHERE LEAST(s."end_pos",  c."hg38_stop")
        - GREATEST(s."start_pos", c."hg38_start") + 1 > 0   -- positive overlap
    GROUP BY
        c."chromosome", c."cytoband_name",
        c."hg38_start", c."hg38_stop", s."case_barcode"
),
band_case_classified AS (        -- rounded CN & CNV class
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND(weighted_sum / overlap_total)                 AS rounded_cn,
        CASE ROUND(weighted_sum / overlap_total)
             WHEN 0 THEN 'Homozygous Deletion'
             WHEN 1 THEN 'Heterozygous Deletion'
             WHEN 2 THEN 'Diploid'
             WHEN 3 THEN 'Gain'
             ELSE           'Amplification'
        END                                                 AS cnv_type
    FROM band_case_weighted
),
band_cnv_counts AS (             -- counts of CNV types per cytoband
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        SUM(IFF(cnv_type = 'Homozygous Deletion',   1, 0)) AS homo_del_cnt,
        SUM(IFF(cnv_type = 'Heterozygous Deletion', 1, 0)) AS hetero_del_cnt,
        SUM(IFF(cnv_type = 'Diploid',               1, 0)) AS diploid_cnt,
        SUM(IFF(cnv_type = 'Gain',                  1, 0)) AS gain_cnt,
        SUM(IFF(cnv_type = 'Amplification',         1, 0)) AS ampl_cnt
    FROM band_case_classified
    GROUP BY
        "chromosome", "cytoband_name", "hg38_start", "hg38_stop"
)
SELECT
    b."chromosome",
    b."cytoband_name",
    b."hg38_start",
    b."hg38_stop",
    ROUND(b.homo_del_cnt   * 100.0 / t.total_cases, 2) AS "pct_homozygous_deletion",
    ROUND(b.hetero_del_cnt * 100.0 / t.total_cases, 2) AS "pct_heterozygous_deletion",
    ROUND(b.diploid_cnt    * 100.0 / t.total_cases, 2) AS "pct_diploid",
    ROUND(b.gain_cnt       * 100.0 / t.total_cases, 2) AS "pct_gain",
    ROUND(b.ampl_cnt       * 100.0 / t.total_cases, 2) AS "pct_amplification"
FROM band_cnv_counts b
CROSS JOIN total_cases t
ORDER BY                                                    -- chromosome order
    COALESCE(
        TRY_TO_NUMBER(REPLACE(b."chromosome",'chr','')),
        CASE WHEN REPLACE(b."chromosome",'chr','') = 'X' THEN 23
             WHEN REPLACE(b."chromosome",'chr','') = 'Y' THEN 24
             ELSE 99 END
    ) NULLS LAST,
    b."hg38_start" NULLS LAST;