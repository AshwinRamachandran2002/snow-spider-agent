WITH t2_studies AS (   -- studies that have T2‑weighted axial MR series
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" IS NOT NULL
      AND LOWER("SeriesDescription") LIKE '%t2%'
      AND (LOWER("SeriesDescription") LIKE '%ax%' OR LOWER("SeriesDescription") LIKE '%axial%')
),
pz_seg_studies AS (    -- studies that contain “Peripheral zone” segmentations
    SELECT DISTINCT s."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS AS s
    JOIN IDC.IDC_V17.DICOM_ALL      AS d
          ON s."SOPInstanceUID" = d."SOPInstanceUID"
    WHERE d."collection_id" = 'qin_prostate_repeatability'
      AND LOWER(TO_VARCHAR(s."SegmentedPropertyType")) LIKE '%peripheral zone%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_studies t
JOIN pz_seg_studies p
  ON t."StudyInstanceUID" = p."StudyInstanceUID"
ORDER BY t."StudyInstanceUID";