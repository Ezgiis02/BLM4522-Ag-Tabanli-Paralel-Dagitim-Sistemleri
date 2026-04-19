-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Adım 5: Erişim Yönetimi
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- Sorgu 1: Mevcut kullanıcıları ve rolleri listele
-- Sonuç: dbo (WINDOWS_USER, db_owner), guest (SQL_USER, NULL)
SELECT dp.name AS KullaniciAdi, dp.type_desc AS Tur,
       rp.name AS RolAdi
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
WHERE dp.type NOT IN ('R') AND dp.name NOT IN ('sys','INFORMATION_SCHEMA')
ORDER BY dp.name;

-- Sorgu 2: Login oluşturma (master veritabanında çalıştırılır)
-- Sonuç: Komutlar başarıyla tamamlandı.
USE master;

CREATE LOGIN taxi_reader WITH PASSWORD = 'Reader123!';
CREATE LOGIN taxi_writer WITH PASSWORD = 'Writer123!';

-- Sorgu 3: Veritabanı kullanıcıları oluşturma ve rol atama
-- Sonuç: Komutlar başarıyla tamamlandı.
USE NYCTaxi_Sample;

CREATE USER taxi_reader FOR LOGIN taxi_reader;
CREATE USER taxi_writer FOR LOGIN taxi_writer;

-- taxi_reader: sadece okuma yetkisi
EXEC sp_addrolemember 'db_datareader', 'taxi_reader';

-- taxi_writer: okuma + yazma yetkisi
EXEC sp_addrolemember 'db_datareader', 'taxi_writer';
EXEC sp_addrolemember 'db_datawriter', 'taxi_writer';

-- Sorgu 4: Kullanıcı rol üyeliklerini doğrula
-- Sonuç: taxi_reader → db_datareader
--        taxi_writer → db_datareader, db_datawriter
SELECT dp.name AS KullaniciAdi,
       rp.name AS RolAdi,
       rp.type_desc AS RolTuru
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
WHERE dp.name IN ('taxi_reader', 'taxi_writer')
ORDER BY dp.name;

-- Sorgu 5: Nesne bazında izinleri listele
-- Sonuç: taxi_reader → GRANT CONNECT, taxi_writer → GRANT CONNECT
SELECT
    pr.name AS KullaniciAdi,
    pe.state_desc AS IzinDurumu,
    pe.permission_name AS IzinAdi,
    OBJECT_NAME(pe.major_id) AS NesneAdi
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('taxi_reader', 'taxi_writer');
