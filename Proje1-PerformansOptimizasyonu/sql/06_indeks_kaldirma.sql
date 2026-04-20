-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu
-- Adım 6: Gereksiz İndeks Kaldırma
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- Sorgu 1: Mevcut indeks durumu (başlangıç)
-- Sonuç: Sadece nyc_cci (CLUSTERED COLUMNSTORE) mevcut
SELECT i.name AS IndeksAdi,
       i.type_desc AS IndeksTipi,
       OBJECT_NAME(i.object_id) AS TabloAdi
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) = 'nyctaxi_sample'
AND i.name IS NOT NULL;

-- Sorgu 2: B-Tree indeks oluştur (kaldırma demonstrasyonu için)
-- Sonuç: IX_nyctaxi_pickup_datetime başarıyla oluşturuldu
CREATE INDEX IX_nyctaxi_pickup_datetime
ON nyctaxi_sample(pickup_datetime);

SELECT i.name AS IndeksAdi,
       i.type_desc AS IndeksTipi,
       OBJECT_NAME(i.object_id) AS TabloAdi
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) = 'nyctaxi_sample'
AND i.name IS NOT NULL;

-- Sorgu 3: Gereksiz B-Tree indeksi kaldır
-- Columnstore index tüm sütunları kapsadığından B-Tree indeks gereksizdir
-- Sonuç: DROP INDEX başarılı, sadece nyc_cci kaldı
DROP INDEX IX_nyctaxi_pickup_datetime ON nyctaxi_sample;

SELECT i.name AS IndeksAdi,
       i.type_desc AS IndeksTipi,
       OBJECT_NAME(i.object_id) AS TabloAdi
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) = 'nyctaxi_sample'
AND i.name IS NOT NULL;
