SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM IDC.IDC_V17."DICOM_PIVOT"
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND (
        "SeriesDescription" ILIKE '%dwi%'                                   -- DWI series
     OR "SeriesDescription" ILIKE '%t2%axial%'                              -- T2‑Weighted Axial series
     OR "SeriesDescription" ILIKE '%apparent%diffusion%coefficient%'        -- ADC series
     OR ("Modality" = 'SEG' AND "SeriesDescription" ILIKE '%t2%axial%')     -- T2‑Weighted Axial segmentations
  );