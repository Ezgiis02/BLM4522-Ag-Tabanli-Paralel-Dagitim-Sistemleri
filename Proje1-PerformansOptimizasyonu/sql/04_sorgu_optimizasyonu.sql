-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Adım 4: Sorgu Optimizasyonu
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- Sorgu 1: Optimize edilmemiş sorgu - YEAR() fonksiyonu kullanımı
-- NOT: Fonksiyon kullanımı indeksin atlanmasına neden olabilir (sarg-ability sorunu)
-- Sonuç: CRD → 918.668, CSH → 778.170, NOC → 4.029, UNK → 1.917, DIS → 1.173
SELECT
    payment_type,
    COUNT(*) AS YolculukSayisi,
    AVG(fare_amount) AS OrtalamaUcret,
    AVG(tip_amount) AS OrtalamaBahsis,
    AVG(trip_distance) AS OrtalamaMesafe
FROM nyctaxi_sample
WHERE YEAR(pickup_datetime) = 2013
GROUP BY payment_type
ORDER BY YolculukSayisi DESC;

-- Sorgu 2: Optimize edilmiş sorgu - Tarih aralığı karşılaştırması
-- NOT: Doğrudan tarih aralığı kullanımı indeks seek'e izin verir
-- Sonuç: Aynı sonuçlar (CRD → 918.668, CSH → 778.170 ...), daha verimli çalışma
SELECT
    payment_type,
    COUNT(*) AS YolculukSayisi,
    AVG(fare_amount) AS OrtalamaUcret,
    AVG(tip_amount) AS OrtalamaBahsis,
    AVG(trip_distance) AS OrtalamaMesafe
FROM nyctaxi_sample
WHERE pickup_datetime >= '2013-01-01' AND pickup_datetime < '2014-01-01'
GROUP BY payment_type
ORDER BY YolculukSayisi DESC;

-- Sorgu 3: Karmaşık filtreli sorgu - Execution Plan analizi
-- Uzun mesafeli (>10 km) ve çok yolculu (>1) seyahatlerin ücret analizi
-- Sonuç: TOP 1000 kayıt, max total_amount = 315,97
-- Execution Plan: "Yürütme planı" sekmesinden indeks kullanımı gözlemlendi
SELECT TOP 1000
    vendor_id,
    passenger_count,
    trip_distance,
    fare_amount,
    total_amount
FROM nyctaxi_sample
WHERE trip_distance > 10
  AND passenger_count > 1
ORDER BY total_amount DESC;

-- Sorgu 4: En pahalı 10 yolculuk
-- Sonuç: En yüksek total_amount = 500 (trip_distance = 1,3 ile aykırı değer)
SELECT TOP 10
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    tip_amount,
    total_amount
FROM nyctaxi_sample
ORDER BY total_amount DESC;
