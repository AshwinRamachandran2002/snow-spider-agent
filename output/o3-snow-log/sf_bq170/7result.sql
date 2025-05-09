/* ---------------------------------------------------------------
   Cytoband-level CNV frequencies for TCGA-BRCA (GDC Release 23)
   ---------------------------------------------------------------*/
WITH cytobands AS (                      -- hg38 cytobands
    SELECT  "chromosome",
            "hg38_start",
            "hg38_stop",
            "cytoband_name"
    FROM    TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),
brca_segments AS (                       -- BRCA allelic segments, R23
    SELECT  "project_short_name",
            "case_barcode",
            "chromosome",
            "start_pos",
            "end_pos",
            "copy_number"
    FROM    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE   "project_short_name" = 'TCGA-BRCA'
),
intersection AS (                        -- segment ↔ cytoband overlaps
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        bs."case_barcode",
        GREATEST(cb."hg38_start", bs."start_pos") AS inter_start,
        LEAST  (cb."hg38_stop" , bs."end_pos"  ) AS inter_end,
        bs."copy_number"
    FROM cytobands cb
    JOIN brca_segments bs
      ON cb."chromosome" = bs."chromosome"
     AND bs."end_pos"   >= cb."hg38_start"
     AND bs."start_pos" <= cb."hg38_stop"
),
overlaps AS (                            -- keep positive-length overlaps
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        (inter_end - inter_start + 1) AS overlap_len,
        "copy_number"
    FROM intersection
    WHERE inter_end >= inter_start
),
weighted_cn AS (                         -- weighted average CN per band/case
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND(
            SUM(overlap_len * "copy_number") :: FLOAT
            / NULLIF(SUM(overlap_len), 0)
        ) AS rounded_cn
    FROM overlaps
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop", "case_barcode"
),
categorized AS (                         -- map CN to CNV category
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        CASE
            WHEN rounded_cn = 0 THEN 'Homozygous Deletion'
            WHEN rounded_cn = 1 THEN 'Heterozygous Deletion'
            WHEN rounded_cn = 2 THEN 'Diploid'
            WHEN rounded_cn = 3 THEN 'Gain'
            ELSE                    'Amplification'
        END AS cnv_type
    FROM weighted_cn
),
total_cases AS (                         -- total unique BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM   brca_segments
)
SELECT
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",
    ROUND(100.0 * SUM(IFF(c.cnv_type = 'Homozygous Deletion', 1, 0)) / tc.n_cases, 2) AS pct_homozygous_deletion,
    ROUND(100.0 * SUM(IFF(c.cnv_type = 'Heterozygous Deletion', 1, 0)) / tc.n_cases, 2) AS pct_heterozygous_deletion,
    ROUND(100.0 * SUM(IFF(c.cnv_type = 'Diploid',               1, 0)) / tc.n_cases, 2) AS pct_diploid,
    ROUND(100.0 * SUM(IFF(c.cnv_type = 'Gain',                  1, 0)) / tc.n_cases, 2) AS pct_gain,
    ROUND(100.0 * SUM(IFF(c.cnv_type = 'Amplification',         1, 0)) / tc.n_cases, 2) AS pct_amplification
FROM   categorized c
CROSS  JOIN total_cases tc
GROUP  BY c."cytoband_name", c."hg38_start", c."hg38_stop", tc.n_cases
ORDER  BY c."cytoband_name" ASC NULLS LAST;