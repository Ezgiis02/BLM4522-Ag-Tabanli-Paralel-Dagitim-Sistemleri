-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Adım 2: Dynamic Management Views (DMV) ile İzleme
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- Sorgu 1: En çok kaynak kullanan TOP 10 sorgu
-- sys.dm_exec_query_stats: Önbelleğe alınmış sorgu planlarının istatistiklerini gösterir
SELECT TOP 10
    qs.execution_count,
    qs.total_elapsed_time / 1000 AS elapsed_ms,
    qs.total_worker_time / 1000 AS cpu_ms,
    qs.total_logical_reads,
    SUBSTRING(qt.text, 1, 100) AS sql_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_elapsed_time DESC;
-- Sonuç: En pahalı sorgu 129ms elapsed, 127ms CPU, 129.394 logical read kullandı

-- Sorgu 2: Aktif kullanıcı oturumları
-- sys.dm_exec_sessions: Tüm aktif oturumları listeler
SELECT
    session_id,
    status,
    cpu_time,
    memory_usage,
    total_elapsed_time,
    login_name,
    host_name
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;
-- Sonuç: 4 aktif oturum tespit edildi, session 61 en fazla CPU kullanımına sahip (2671ms)

-- Sorgu 3: Veritabanı dosya boyutları
-- sys.database_files: Veritabanı dosyalarının boyutlarını gösterir
SELECT
    DB_NAME() AS VeritabaniAdi,
    name AS DosyaAdi,
    size * 8 / 1024 AS BoyutMB,
    type_desc AS DosyaTuru
FROM sys.database_files;
-- Sonuç: Veri dosyası 136MB, Log dosyası 136MB = Toplam 272MB

-- Sorgu 4: Tablo bazında satır sayısı ve alan kullanımı
-- sys.dm_db_partition_stats: Tablo/indeks bölüm istatistiklerini gösterir
SELECT
    OBJECT_NAME(object_id) AS TabloAdi,
    row_count AS SatirSayisi,
    reserved_page_count * 8 AS ToplamKB,
    used_page_count * 8 AS KullanilanKB
FROM sys.dm_db_partition_stats
WHERE object_id > 100;
-- Sonuç: nyctaxi_sample → 1.703.957 satır, 94.856KB toplam, 86.952KB kullanılan
