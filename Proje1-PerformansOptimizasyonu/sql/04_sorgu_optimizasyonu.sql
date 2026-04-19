-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Adım 4: Sorgu Optimizasyonu
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- Sorgu 1: Optimize edilmemiş sorgu - YEAR() fonksiyonu kullanımı
-- NOT: Fonksiyon kullanımı indeksin atlanmasına neden olabilir (index sarg-ability sorunu)
-- Sonuç: CRD → 918.668, CSH → 778.170 yolculuk
SELECT payment_type, COUNT(*) AS Adet
FROM nyctaxi_sample
WHERE YEAR(pickup_datetime) = 2013
GROUP BY payment_type;

-- Sorgu 2: Optimize edilmiş sorgu - Tarih aralığı karşılaştırması
-- NOT: Doğrudan tarih aralığı kullanımı indeks seek'e izin verir
-- Sonuç: CRD → 918.668, CSH → 778.170 (aynı sonuç, daha hızlı çalışma)
SELECT payment_type, COUNT(*) AS Adet
FROM nyctaxi_sample
WHERE pickup_datetime >= '2013-01-01' AND pickup_datetime < '2014-01-01'
GROUP BY payment_type;

-- Sorgu 3: Karmaşık filtreli sorgu - Execution Plan analizi
-- Uzun mesafeli ve çok yolculu seyahatlerin toplam ücret analizi
-- Sonuç: TOP 1000 kayıt, max total_amount = 315.97
-- Execution Plan: Index Seek kullanıldığı gözlemlendi
SELECT TOP 1000
    trip_distance,
    passenger_count,
    total_amount
FROM nyctaxi_sample
WHERE trip_distance > 10
  AND passenger_count > 1
ORDER BY total_amount DESC;

-- Sorgu 4: En pahalı 10 yolculuk
-- Sonuç: En yüksek total_amount = 500
SELECT TOP 10
    medallion,
    hack_license,
    trip_distance,
    passenger_count,
    total_amount
FROM nyctaxi_sample
ORDER BY total_amount DESC;
