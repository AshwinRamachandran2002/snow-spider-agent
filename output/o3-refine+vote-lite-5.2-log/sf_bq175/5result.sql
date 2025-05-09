WITH kirc_seg_chr1 AS (
    SELECT 
        s."start_pos",
        s."end_pos",
        s."copy_number"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome" = 'chr1'
), band_map AS (
    SELECT 
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop"
    FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" b
    WHERE b."chromosome" = 'chr1'
), seg_band AS (
    SELECT
        bm."cytoband_name",
        CASE WHEN ks."copy_number" > 3 THEN 1 ELSE 0 END AS is_amp,
        CASE WHEN ks."copy_number" = 3 THEN 1 ELSE 0 END AS is_gain,
        CASE WHEN ks."copy_number" = 1 THEN 1 ELSE 0 END AS is_hetdel
    FROM kirc_seg_chr1 ks
    JOIN band_map bm
      ON ks."end_pos"   >= bm."hg38_start"
     AND ks."start_pos" <= bm."hg38_stop"
), agg AS (
    SELECT
        "cytoband_name",
        SUM(is_amp)    AS amp_cnt,
        SUM(is_gain)   AS gain_cnt,
        SUM(is_hetdel) AS hetdel_cnt
    FROM seg_band
    GROUP BY "cytoband_name"
), ranked AS (
    SELECT
        a.*,
        DENSE_RANK() OVER (ORDER BY amp_cnt    DESC) AS amp_rank,
        DENSE_RANK() OVER (ORDER BY gain_cnt   DESC) AS gain_rank,
        DENSE_RANK() OVER (ORDER BY hetdel_cnt DESC) AS hetdel_rank
    FROM agg a
)
SELECT
    "cytoband_name",
    amp_cnt,
    gain_cnt,
    hetdel_cnt,
    amp_rank,
    gain_rank,
    hetdel_rank
FROM ranked
WHERE amp_rank    <= 11
  AND gain_rank   <= 11
  AND hetdel_rank <= 11
ORDER BY "cytoband_name";